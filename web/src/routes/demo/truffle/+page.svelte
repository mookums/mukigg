<script lang="ts">
    import { base } from "$app/paths";
    import Header from "$lib/Header.svelte";
    import { onMount } from "svelte";
    import init, { create_simulator, execute_sql, free_simulator } from "truffle-wasm";

    let simulator = $state(0);

    onMount(async () => {
        await init();
        simulator = create_simulator();
    });
</script>

<div>
    <Header />
    <main class="flex flex-col items-center">
        <main class="flex flex-col items-center">
            {#if simulator}
                <p>Simulator initialized!</p>
            {:else}
                <p>Loading simulator...</p>
            {/if}
        </main>
    </main>
</div>
