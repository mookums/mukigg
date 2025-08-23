<script lang="ts">
    import { base } from "$app/paths";
    import Header from "$lib/Header.svelte";
    import { onDestroy, onMount } from "svelte";
    import init, {
        create_simulator,
        execute_sql,
        free_simulator,
        get_constraints,
        get_table,
        get_tables,
    } from "../../../../../truffle-wasm/pkg";

    import { Effect, pipe } from "effect";

    let simulator = $state<number | null>(null);

    let baseConsoleLines = [
        "truffle repl",
        "type any sql expression and it will be evaluated",
        "use .help to see the help menu.",
    ];

    let consoleLines = $state(baseConsoleLines);
    let currentInput = $state("");
    let isFullscreen = $state(false);
    let consoleElement = $state<HTMLElement>();

    onMount(async () => {
        await init();
        simulator = create_simulator();
    });

    onDestroy(() => {
        if (simulator) {
            free_simulator(simulator);
        }
    });

    const executeCommand = () => {
        const executeWithLogging = <T,>(
            effect: Effect.Effect<T, any, never>,
            formatSuccess?: (result: T) => string,
        ) => {
            return pipe(
                effect,
                Effect.match({
                    onFailure: (error) => {
                        consoleLines.push(`✕ ${error}`);
                        consoleLines.push("");
                    },
                    onSuccess: (result) => {
                        const output = formatSuccess ? formatSuccess(result) : String(result);
                        const lines = output.split("\n");
                        consoleLines.push(...lines);
                        consoleLines.push("");
                    },
                }),
                Effect.runSync,
            );
        };

        const formatConstraints = (constraints: any) => {
            return [...constraints.entries()]
                .map(([key, val]) => {
                    if (Array.isArray(val)) {
                        // Process each constraint in the array
                        const formattedConstraints = val.map((constraint) => {
                            if (typeof constraint === "string") {
                                return constraint;
                            } else if (
                                constraint &&
                                typeof constraint === "object" &&
                                constraint.ForeignKey
                            ) {
                                const fk = constraint.ForeignKey;
                                return `FK → ${fk.foreign_table}(${fk.foreign_columns.join(", ")}) ON DELETE ${fk.on_delete} ON UPDATE ${fk.on_update}`;
                            } else {
                                return JSON.stringify(constraint);
                            }
                        });
                        return `    ⤷ ${key}: [${formattedConstraints.join(", ")}]`;
                    } else {
                        return `    ⤷ ${key}: ${val}`;
                    }
                })
                .join("\n");
        };

        const formatTable = (table: any) => {
            const formattedColumns = [...table.columns.entries()]
                .map(([key, col]) => {
                    const parts = [`Type: ${col.ty}`];
                    if (col.unique) parts.push("Unique");
                    if (col.default) parts.push("Default");
                    return `    ⤷ ${key}: ${parts.join(", ")}`;
                })
                .join("\n");

            const formattedConstraints = formatConstraints(table.constraints);

            return `⤷ Columns:\n${formattedColumns}\n⤷ Constraints:\n${formattedConstraints}`;
        };

        const formatResolved = (resolved: any) => {
            const formattedInputs =
                resolved.inputs.length > 0
                    ? [...resolved.inputs]
                          .map((col, i) => {
                              const parts = [`Type: ${col.ty}`];
                              if (col.unique) parts.push("Unique");
                              if (col.default) parts.push("Default");
                              return `    ⤷ $${i + 1}: ${parts.join(", ")}`;
                          })
                          .join("\n")
                    : "    (none)";

            const formattedOutputs =
                resolved.outputs.size > 0
                    ? [...resolved.outputs.entries()]
                          .map(([key, col]) => {
                              const formattedRef = `${key.qualifier ? key.qualifier + "." : ""}${key.name}`;
                              const parts = [`Type: ${col.ty}`];
                              if (col.unique) parts.push("Unique");
                              if (col.default) parts.push("Default");
                              return `    ⤷ ${formattedRef}: ${parts.join(", ")}`;
                          })
                          .join("\n")
                    : "    (none)";

            return `⤷ Inputs:\n${formattedInputs}\n⤷ Outputs:\n${formattedOutputs}`;
        };

        if (!currentInput.trim()) return;

        const totalInput = currentInput.trim().toLowerCase();
        consoleLines.push(`> ${totalInput}`);
        let split = totalInput.split(" ");
        let command = split[0];
        let arg = split[1];

        if (command === ".help") {
            consoleLines.push("Available commands:");
            consoleLines.push("  • SQL queries (SELECT, INSERT, UPDATE, DELETE, etc.)");
            consoleLines.push("  • '.table <NAME>' - print out information about table");
            consoleLines.push("  • '.tables' - print out all tables");
            consoleLines.push(
                "  • '.constraints <NAME>' - print out information about constraints",
            );
            consoleLines.push("  • '.clear' - clear the console");
            consoleLines.push("  • '.reset' - reset the simulator");
            consoleLines.push("  • '.help' - show this help message");
            consoleLines.push("");
        } else if (command === ".clear") {
            consoleLines = baseConsoleLines;
        } else if (command === ".reset") {
            if (simulator) {
                free_simulator(simulator);
            }
            simulator = create_simulator();
            consoleLines.push("! truffle has been reset.");
            consoleLines.push("");
        } else if (command === ".tables") {
            pipe(
                Effect.try({
                    try: () => get_tables(simulator!),
                    catch: (e) => e as string,
                }),
                Effect.map((tables) => `⤷ [${tables.join(", ")}]`),
                executeWithLogging,
            );
        } else if (command === ".table") {
            pipe(
                Effect.try({
                    try: () => get_table(simulator!, arg),
                    catch: (e) => e as string,
                }),
                Effect.flatMap((table) =>
                    table
                        ? Effect.succeed(formatTable(table))
                        : Effect.fail(`Table "${arg}" not found.`),
                ),
                executeWithLogging,
            );
        } else if (command === ".constraints") {
            pipe(
                Effect.try({
                    try: () => get_constraints(simulator!, arg),
                    catch: (e) => e as string,
                }),
                Effect.flatMap((constraints) =>
                    constraints
                        ? Effect.succeed(formatConstraints(constraints))
                        : Effect.fail(`Table "${arg}" not found.`),
                ),
                executeWithLogging,
            );
        } else {
            pipe(
                Effect.try({
                    try: () => execute_sql(simulator!, totalInput),
                    catch: (e) => e as string,
                }),
                Effect.map((resolved) => formatResolved(resolved)),
                executeWithLogging,
            );
        }

        currentInput = "";

        // Scroll to the bottom.
        setTimeout(() => {
            if (consoleElement) {
                consoleElement.scrollTop = consoleElement.scrollHeight;
            }
        }, 0);
    };

    const handleKeyDown = (event: KeyboardEvent) => {
        if (event.key === "Enter") {
            executeCommand();
        }
    };
</script>

<svelte:head>
    <title>muki.gg / Truffle Demo</title>
</svelte:head>

<div>
    {#if !isFullscreen}
        <Header />
    {/if}
    <main class="flex flex-col flex-grow justify-center items-center mb-8">
        <div class="flex flex-col justify-center items-center w-screen gap-y-8 relative">
            {#if !isFullscreen}
                <section class="flex flex-col text-center w-[70%] m-4 gap-y-2" id="title">
                    <hgroup class="flex flex-col justify-center items-center gap-y-2">
                        <h2 class="text-2xl mb-1 font-medium">Truffle Demo</h2>
                        <p>
                            Truffle is an SQL static analyzer. It maintains a stateful schema from
                            previously run SQL queries and is able to verify various constraints,
                            including type-checking expressions and verifying foreign keys.
                        </p>
                        <p>
                            You can start reading about it <a
                                class="hyper-blue"
                                href="{base}/posts/sql-static-analysis-intro">here</a
                            >. You can view the source code
                            <a class="hyper-blue" href="https://github.com/mookums/truffle">here</a
                            >.
                        </p>
                        <span class="text-sm">Version 0.2.0</span>
                    </hgroup>
                </section>
            {/if}

            <div
                class="{isFullscreen
                    ? 'fixed top-0 left-0 right-0 h-[75vh] my-8 z-50'
                    : 'h-[50vh] relative max-w-4xl'} flex flex-col p-4 whitespace-pre-wrap border-2 border-neutral-400 rounded-lg bg-white items-center w-[90%] mx-auto"
            >
                <button
                    class="absolute top-2 right-4 z-10 cursor-pointer"
                    onclick={() => {
                        isFullscreen = !isFullscreen;
                    }}
                >
                    {#if isFullscreen}
                        ↙
                    {:else}
                        ↗
                    {/if}
                </button>

                <!-- Inner scrollable area -->
                <div
                    bind:this={consoleElement}
                    class="flex flex-col flex-grow overflow-y-auto w-full"
                >
                    {#if simulator}
                        {#each consoleLines as line, i}
                            {#if line.length == 0}
                                <div
                                    class="flex h-[1rem] {i === consoleLines.length - 1
                                        ? 'flex-grow'
                                        : ''}"
                                ></div>
                            {:else}
                                <span
                                    class="flex {i === consoleLines.length - 1 ? 'flex-grow' : ''}"
                                >
                                    {line}
                                </span>
                            {/if}
                        {/each}
                        <div class="flex flex-col gap-y-2 mt-2 sticky bottom-0 bg-white">
                            <div class="flex items-center gap-x-2">
                                <span>λ </span>
                                <input
                                    bind:value={currentInput}
                                    onkeydown={handleKeyDown}
                                    class="flex-1 bg-transparent border-none outline-none font-mono"
                                    placeholder="..."
                                    autocomplete="off"
                                    spellcheck="false"
                                />
                            </div>
                            <p class="hidden lg:flex whitespace-nowrap text-xs text-neutral-600">
                                Truffle is experimental and only supports a subset of the SQL
                                standard.
                            </p>
                        </div>
                    {:else}
                        <p>Loading simulator...</p>
                    {/if}
                </div>
            </div>
        </div>
    </main>
</div>
