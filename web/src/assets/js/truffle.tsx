import { render } from 'preact';
import { useState, useEffect, useRef } from 'preact/hooks';
import init, {
  create_simulator,
  execute_sql,
  free_simulator,
  get_constraints,
  get_table,
  get_tables,
} from '../../../../truffle-wasm/pkg/truffle_wasm.js';

function TruffleDemo() {
  const [simulator, setSimulator] = useState<number | null>(null);
  const [consoleLines, setConsoleLines] = useState([
    "truffle repl",
    "type any sql expression and it will be evaluated",
    "use .help to see the help menu.",
  ]);
  const [currentInput, setCurrentInput] = useState("");
  const [isFullscreen, setIsFullscreen] = useState(false);
  const consoleRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    const initSimulator = async () => {
      await init();
      setSimulator(create_simulator());
    };
    initSimulator();

    return () => {
      if (simulator) free_simulator(simulator);
    };
  }, []);

  useEffect(() => {
    if (consoleRef.current) {
      consoleRef.current.scrollTop = consoleRef.current.scrollHeight;
    }
  }, [consoleLines]);

  const formatConstraints = (constraints: any) => {
    return [...constraints.entries()]
      .map(([key, val]) => {
        if (Array.isArray(val)) {
          const formattedConstraints = val.map((constraint) => {
            if (typeof constraint === "string") {
              return constraint;
            } else if (constraint?.ForeignKey) {
              const fk = constraint.ForeignKey;
              return `FK → ${fk.foreign_table}(${fk.foreign_columns.join(", ")}) ON DELETE ${fk.on_delete} ON UPDATE ${fk.on_update}`;
            }
            return JSON.stringify(constraint);
          });
          return `    ⤷ ${key}: [${formattedConstraints.join(", ")}]`;
        }
        return `    ⤷ ${key}: ${val}`;
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
    const formattedInputs = resolved.inputs.length > 0
      ? [...resolved.inputs]
        .map((col, i) => {
          const parts = [`Type: ${col.ty}`];
          if (col.unique) parts.push("Unique");
          if (col.default) parts.push("Default");
          return `    ⤷ $${i + 1}: ${parts.join(", ")}`;
        })
        .join("\n")
      : "    (none)";

    const formattedOutputs = resolved.outputs.size > 0
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

  const executeCommand = () => {
    if (!currentInput.trim()) return;

    const totalInput = currentInput.trim().toLowerCase();
    const newLines = [...consoleLines, `> ${totalInput}`];
    const split = totalInput.split(" ");
    const command = split[0];
    const arg = split[1];

    try {
      if (command === ".help") {
        newLines.push(
          "Available commands:",
          "  • SQL queries (SELECT, INSERT, UPDATE, DELETE, etc.)",
          "  • '.table <NAME>' - print out information about table",
          "  • '.tables' - print out all tables",
          "  • '.constraints <NAME>' - print out information about constraints",
          "  • '.clear' - clear the console",
          "  • '.reset' - reset the simulator",
          "  • '.help' - show this help message",
          ""
        );
      } else if (command === ".clear") {
        setConsoleLines([
          "truffle repl",
          "type any sql expression and it will be evaluated",
          "use .help to see the help menu.",
        ]);
        setCurrentInput("");
        return;
      } else if (command === ".reset") {
        if (simulator) free_simulator(simulator);
        const newSim = create_simulator();
        setSimulator(newSim);
        newLines.push("! truffle has been reset.", "");
      } else if (command === ".tables") {
        const tables = get_tables(simulator!);
        newLines.push(`⤷ [${tables.join(", ")}]`, "");
      } else if (command === ".table") {
        const table = get_table(simulator!, arg);
        if (table) {
          newLines.push(...formatTable(table).split("\n"), "");
        } else {
          newLines.push(`✕ Table "${arg}" not found.`, "");
        }
      } else if (command === ".constraints") {
        const constraints = get_constraints(simulator!, arg);
        if (constraints) {
          newLines.push(...formatConstraints(constraints).split("\n"), "");
        } else {
          newLines.push(`✕ Table "${arg}" not found.`, "");
        }
      } else {
        const resolved = execute_sql(simulator!, totalInput);
        newLines.push(...formatResolved(resolved).split("\n"), "");
      }
    } catch (error) {
      newLines.push(`✕ ${error}`, "");
    }

    setConsoleLines(newLines);
    setCurrentInput("");
  };

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === "Enter") executeCommand();
  };

  return (
    <div>
      <main class="flex flex-col flex-grow justify-center items-center mb-8">
        <div class="flex flex-col justify-center items-center w-screen gap-y-8 relative">
          {!isFullscreen && (
            <section class="flex flex-col text-center w-[70%] m-4 gap-y-2" id="title">
              <hgroup class="flex flex-col justify-center items-center gap-y-2">
                <h2 class="text-2xl mb-1 font-medium">Truffle Demo</h2>
                <p>
                  Truffle is an SQL static analyzer. It maintains a stateful schema from
                  previously run SQL queries and is able to verify various constraints,
                  including type-checking expressions and verifying foreign keys.
                </p>
                <p>
                  You can view the source code <a class="hyper-blue" href="https://github.com/mookums/truffle">here</a>.
                </p>
                <span class="text-sm">Version 0.2.0</span>
              </hgroup>
            </section>
          )}

          <div
            class={`${isFullscreen
              ? "fixed top-0 left-0 right-0 h-[75vh] my-8 z-50"
              : "h-[50vh] relative max-w-4xl"
              } flex flex-col p-4 whitespace-pre-wrap border-2 border-neutral-400 rounded-lg bg-white items-center w-[90%] mx-auto`}
          >
            <button
              class="absolute top-2 right-4 z-10 cursor-pointer"
              onClick={() => setIsFullscreen(!isFullscreen)}
            >
              {isFullscreen ? "↙" : "↗"}
            </button>

            <div ref={consoleRef} class="flex flex-col flex-grow overflow-y-auto w-full">
              {simulator ? (
                <>
                  {consoleLines.map((line, i) =>
                    line.length === 0 ? (
                      <div
                        key={i}
                        class={`flex h-[1rem] ${i === consoleLines.length - 1 ? "flex-grow" : ""
                          }`}
                      />
                    ) : (
                      <span
                        key={i}
                        class={`flex ${i === consoleLines.length - 1 ? "flex-grow" : ""
                          }`}
                      >
                        {line}
                      </span>
                    )
                  )}
                  <div class="flex flex-col gap-y-2 mt-2 sticky bottom-0 bg-white">
                    <div class="flex items-center gap-x-2">
                      <span>λ </span>
                      <input
                        value={currentInput}
                        onKeyDown={handleKeyDown}
                        class="flex-1 bg-transparent border-none outline-none font-mono"
                        placeholder="..."
                        autocomplete="off"
                      />
                    </div>
                    <p class="hidden lg:flex whitespace-nowrap text-xs text-neutral-600">
                      Truffle is experimental and only supports a subset of the SQL
                      standard.
                    </p>
                  </div>
                </>
              ) : (
                <p>Loading simulator...</p>
              )}
            </div>
          </div>
        </div>
      </main >
    </div >
  );
}

render(<TruffleDemo />, document.getElementById('app')!);
