<script lang="ts">
    import { base } from "$app/paths";
    import Header from "$lib/Header.svelte";
</script>

<div>
    <Header />
    <main class="flex flex-col items-center">
        <div class="max-w-2xl px-3 py-12">
            <section class="flex flex-col gap-y-4" id="about">
                <p>
                    hello! i'm muki and i'm a computer engineer from seattle. this website is mostly
                    just a personal library where i just put things i find interesting.
                </p>
                <p>
                    i'm currently working as a software engineer at <a
                        class="hyper-blue"
                        href="https://lightpanda.io">lightpanda</a
                    > where i work on a headless browser for ai and automation workflows. my day to day
                    is in zig with some c++ when interfacing with v8.
                </p>
                <p>you can contact me at muki@[this_domain].</p>
                <div>
                    <p>historically,</p>
                    <ul class="list-disc list-inside">
                        <li>
                            i worked at <a class="hyper-blue" href="https://pyro.host">pyro</a> where
                            i was a systems software engineer writing rust, zig and nix on a daily basis.
                        </li>
                        <li>
                            i led the flight computer team at huskysat, the university of washington
                            cubesat team.
                        </li>
                        <li>i built and sold a motorsports race management product.</li>
                        <li>i interned at amazon twice working on the amazon approvals team.</li>
                    </ul>
                </div>
            </section>
            <section id="posts" class="my-4">
                <h2 class="text-2xl my-1 cursor-pointer select-none">posts</h2>
                <ul class="flex flex-col gap-y-1">
                    <li>
                        2025-08-20 / <a
                            class="font-bold hyper-blue"
                            href="{base}/posts/sql-static-analysis-intro"
                            >Statically Analyzing SQL: Introduction</a
                        >
                    </li>
                    <li>
                        2024-10-24 / <a
                            class="font-bold hyper-blue"
                            href="{base}/posts/async-runtime">Writing an Async Runtime</a
                        >
                    </li>
                    <!-- <li>
                        2024-09-05 / <a class="font-bold hyper-blue" href="/posts/modular-async"
                            >Modular Async Modeling</a
                        >
                    </li> -->
                </ul>
            </section>
            <section id="demos" class="mb-4">
                <h2 class="text-2xl my-1 cursor-pointer select-none">demos</h2>
                <ul class="flex flex-col gap-y-1">
                    <li>
                        <a class="font-bold" href="{base}/demo/truffle">truffle</a>: a static
                        analyzer and type checker for SQL
                    </li>
                </ul>
            </section>
            <section id="projects" class="mb-4">
                <h2 class="text-2xl my-1 cursor-pointer select-none">projects</h2>
                <ul class="flex flex-col gap-y-1">
                    <li>
                        <a class="font-bold" href="https://github.com/tardy-org/zzz">zzz</a>: a
                        (mostly) HTTP/1.1 compliant web framework, written in Zig.
                    </li>
                    <li>
                        <a class="font-bold" href="https://github.com/tardy-org/tardy">tardy</a>: an
                        asynchronous runtime for writing services and applications, written in Zig.
                        async i/o support using io_uring, epoll and poll. coroutine support for
                        x86_64 (sysv + windows) and aarch64.
                    </li>
                    <li>
                        <a class="font-bold" href="https://github.com/mookums/iguana">iguana</a>: a
                        library for building Zig projects with Nix.
                    </li>
                </ul>
            </section>
        </div>
    </main>
</div>
