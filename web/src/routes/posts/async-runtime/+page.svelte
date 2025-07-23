<script lang="ts">
    import { base } from "$app/paths";
    import Header from "$lib/Header.svelte";
    import hljs from "@highlightjs/cdn-assets/highlight.min.js";
    import { onMount } from "svelte";

    onMount(() => {
        hljs.highlightAll();
    });
</script>

<svelte:head>
    <title>muki.gg / Writing an Async Runtime</title>
</svelte:head>

<div>
    <Header />
    <div class="flex flex-col items-center w-full">
        <div class="flex flex-col w-full max-w-3xl gap-y-2 px-4">
            <section class="m-4" id="title">
                <hgroup class="flex flex-col justify-center items-center">
                    <h2 class="text-2xl mb-1 font-medium">Writing an Async Runtime</h2>
                    <span>Oct. 24th, 2024</span>
                </hgroup>
            </section>
            <section class="flex flex-col gap-y-4" id="intro">
                <h3 class="text-2xl">
                    Introduction <a class="hyper-blue" href="{base}/posts/async-runtime/#intro">#</a
                    >
                </h3>
                <p>
                    While working on zzz, I thought about how I would trigger asynchronous events
                    when already operating in an asynchronous context. An easy way to think about
                    this is making a database call while inside of an HTTP request handler. Our
                    response depends on this database call but we don't want to block execution on
                    our thread while this query resolves.
                </p>
                <p>
                    As I wrote about earlier, Zig doesn't have any async primitives in the language.
                    As a result, this style of execution was not supported by zzz's event loop and
                    requires some higher level management of execution.
                </p>
                <p>
                    A language with <code class="text-pink-500">async/await</code> will
                    automatically handle this case for you in some pretty interesting ways<sup
                        >[1]</sup
                    ><sup>[2]</sup>. This allows your asynchronous code to look like synchronous
                    code. The example below will fetch a set of items from a database and then
                    generate an HTML fragment using a template that depends on this list of items.
                    Behavior like this is currently impossible in zzz.
                </p>
                <div>
                    <p class="text-sm">
                        [1]: <a
                            class="hyper-blue"
                            href="https://www.eventhelix.com/rust/rust-to-assembly-async-await/"
                            >Understanding Async Await in Rust: From State Machines to Assembly Code</a
                        >
                    </p>
                    <p class="text-sm">
                        [2]: <a
                            class="hyper-blue"
                            href="https://cliffle.com/blog/async-inversion/#async-fn-is-an-inversion-of-control"
                            >How to think about async/await in Rust</a
                        >
                    </p>
                </div>
                <pre class="max-w-screen"><code class="rounded-lg"
                        >{`pub async fn get_store_items(
    Extension(db): Extension<PgPool>,
    query: Option<Query<Pagination>>,
) -> impl IntoResponse {
    let Query(query) = query.unwrap_or_default();
    let Ok(items) = sqlx::query_as!(
        ItemOnDisplayInner,
        r#"
        SELECT id, name, price, thumbnail_url
        FROM items
        ORDER BY entry_date DESC
        OFFSET $1 ROWS
        FETCH NEXT $2 ROWS ONLY
        "#,
        (query.page * query.per_page) as i64,
        query.per_page as i64,
    )
    .fetch_all(&db)
    .await
    } else {
        return (StatusCode::NOT_FOUND, Html("".to_string()));
    };
    debug!("Store Items: {items:?}");
    let template = ItemsTemplate {
        items: items.into_iter().map(|item| item.into()).collect(),
    };
    (StatusCode::OK, Html(template.render().unwrap()))
}`}</code
                    ></pre>
                <small
                    >Note: This pattern is a pretty common occurance and benefits greatly from
                    async/await.</small
                >
            </section>
            <section class="flex flex-col gap-y-4" id="async-io">
                <h3 class="text-2xl">
                    Asynchronous I/O <a
                        class="hyper-blue"
                        href="{base}/posts/async-runtime/#async-io">#</a
                    >
                </h3>
                <p>
                    The nice thing about having built zzz first is that I already had a good
                    foundation of asynchronous I/O to work off of. This asynchronous I/O provides
                    the functionality for interacting with the filesystem and the network, by
                    providing various queue operations.
                </p>
                <p>
                    Currently, there are three supported asynchronous backends, <code
                        class="language-zig">io_uring</code
                    >, <code class="language-zig">epoll</code>, and
                    <code class="language-zig">busy_loop</code>. The first two provide support for
                    Linux systems while the <code class="language-zig">busy_loop</code> implementation
                    supports Linux, Mac and Windows. There is also support for custom asynchronous I/O
                    backends that can be passed in at compile time.
                </p>
                <pre><code class="rounded-lg"
                        >{`pub fn queue_open(
    self: *AsyncIO,
    task: usize,
    path: []const u8,
) !void {
    const uring: *AsyncIoUring = @ptrCast(@alignCast(self.runner));
    const borrowed = try uring.jobs.borrow_hint(task);
    borrowed.item.* = .{
        .index = borrowed.index,
        .type = .{ .open = path },
        .task = task,
        .fd = undefined,
    };
    _ = try uring.inner.openat(
        @intFromPtr(borrowed.item),
        std.posix.AT.FDCWD,
        @ptrCast(path.ptr),
        .{},
        0,
    );
}`}</code
                    ></pre>
                <p>
                    Above is an example of queuing a file open with the Asynchronous backend. This
                    code operates within the <code class="language-zig">io_uring</code> backend. We utilize
                    a pool of Job items that allow us to track which action completed later on when we
                    reap events. We borrow from the pool and set a variety of parameters.
                </p>
                <p>
                    There are a variety of other methods that operate in a similar way that have
                    been omitted for brevity but they all handle various operations you want with
                    files or the network.
                </p>
                <p>
                    The important part of this asynchronous I/O system is that it allows us to queue
                    various events and then handle them later when they complete. This reaping
                    behavior will be used later to manage tasks. This callback approach is
                    instrumental in building our runtime as it allows us to creatively interleave
                    different tasks.
                </p>
            </section>
            <section class="flex flex-col gap-y-4" id="scheduler">
                <h3 class="text-2xl">
                    Adding a Scheduler <a
                        class="hyper-blue"
                        href="{base}/posts/async-runtime/#scheduler">#</a
                    >
                </h3>
                <p>
                    Now that we have a way to queue asynchronous I/O events and defer handling the
                    result, we will build a scheduler. This will be a fairly simple scheduler that
                    will run tasks to completion.
                </p>
                <pre><code class="rounded-lg"
                        >{`pub fn run(self: *Runtime) !void {
    while (true) {
        // Bitset that tracks the currently runnable tasks.
        var iter = self.scheduler.runnable.iterator(.{ .kind = .set });
        while (iter.next()) |index| {
            const task: *Task = &self.scheduler.tasks.items[index];
            assert(task.state == .runnable);
            const cloned_task: Task = task.*;
            task.state = .dead;
            try self.scheduler.release(task.index);
            // Run the task.
            @call(.auto, cloned_task.func, .{
                self,
                &cloned_task,
                cloned_task.context,
            }) catch |e| {
                log.debug("task failed: {}", .{e});
            };
        }
        // Submit any Async I/O events that were queued.
        try self.aio.submit();
        // Only wait for I/O if we have no more runnable tasks.
        const wait_for_io = self.scheduler.runnable.count() == 0;
        log.debug("Wait for I/O: {}", .{wait_for_io});
        // For any completions that are generated, we want
        // to set the linked task to runnable.
        const completions = try self.aio.reap(wait_for_io);
        for (completions) |completion| {
            const index = completion.task;
            const task = &self.scheduler.tasks.items[index];
            assert(task.state == .waiting);
            task.result = completion.result;
            self.scheduler.set_runnable(index);
        }
        // End execution when we have no more runnable tasks.
        if (self.scheduler.runnable.count() == 0) {
            log.err("no more runnable tasks", .{});
            break;
        }
}`}</code
                    ></pre>
                <p>
                    When all of the currently runnable tasks have been run, we will have an
                    opportunity to reap all of the Async I/O events that have completed. With all of
                    these completions (completed I/O events), we can now run any tasks that are
                    dependent on it.
                </p>
                <p>
                    This runtime provides us the ability to spawn tasks as runnable (think green
                    thread) and it also allows us to spawn tasks as <code>.waiting</code>, meaning
                    that it gets to run once the linked I/O event completes. This linking behavior
                    is central to the design of this runtime and effectively creates a runtime that
                    yields on I/O bounds.
                </p>
            </section>
            <section class="flex flex-col gap-y-4" id="echo-example">
                <h3 class="text-2xl">
                    TCP Echo Example <a
                        class="hyper-blue"
                        href="{base}/posts/async-runtime/#echo-example">#</a
                    >
                </h3>
                <p>
                    An easy way to do a proof of concept is to write a program that uses TCP to
                    echo. Below will be an example program that will:
                </p>
                <ol class="list-decimal list-inside">
                    <li>Create a Socket</li>
                    <li>Accept on the Socket</li>
                    <li>Set the accepted Socket to non-blocking</li>
                    <li>Recv on that Socket</li>
                    <li>Send back what was received</li>
                    <li>Repeat</li>
                </ol>
                <pre><code
                        >{`const std = @import("std");
const log = std.log.scoped(.@"tardy/example/echo");
const Pool = @import("tardy").Pool;
const Runtime = @import("tardy").Runtime;
const Task = @import("tardy").Task;
const Tardy = @import("tardy").Tardy(.auto);
const Cross = @import("tardy").Cross;
const Provision = struct {
    index: usize,
    socket: std.posix.socket_t,
    buffer: []u8,
};

fn close_connection(provision_pool: *Pool(Provision), provision: *const Provision) void {
    log.debug("closed connection fd={d}", .{provision.socket});
    std.posix.close(provision.socket);
    provision_pool.release(provision.index);
}

fn accept_task(rt: *Runtime, t: *const Task, _: ?*anyopaque) !void {
    const server_socket = rt.storage.get("server_socket", std.posix.socket_t);
    const child_socket = t.result.?.socket;
    try Cross.socket.to_nonblock(child_socket);
    log.debug("{d} - accepted socket fd={d}", .{ std.time.milliTimestamp(), child_socket });
    try rt.net.accept(.{
        .socket = server_socket,
        .func = accept_task,
    });
    // get provision
    // assign based on index
    // get buffer
    const provision_pool = rt.storage.get_ptr("provision_pool", Pool(Provision));
    const borrowed = try provision_pool.borrow();
    borrowed.item.index = borrowed.index;
    borrowed.item.socket = child_socket;
    try rt.net.recv(.{
        .socket = child_socket,
        .buffer = borrowed.item.buffer,
        .func = recv_task,
        .ctx = borrowed.item,
    });
}

fn recv_task(rt: *Runtime, t: *const Task, ctx: ?*anyopaque) !void {
    const provision: *Provision = @ptrCast(@alignCast(ctx.?));
    const length = t.result.?.value;
    if (length <= 0) {
        const provision_pool = rt.storage.get_ptr("provision_pool", Pool(Provision));
        close_connection(provision_pool, provision);
        return;
    }
    try rt.net.send(.{
        .socket = provision.socket,
        .buffer = provision.buffer[0..@intCast(length)],
        .func = send_task,
        .ctx = ctx,
    });
}

fn send_task(rt: *Runtime, t: *const Task, ctx: ?*anyopaque) !void {
    const provision: *Provision = @ptrCast(@alignCast(ctx.?));
    const length = t.result.?.value;
    if (length <= 0) {
        const provision_pool = rt.storage.get_ptr("provision_pool", Pool(Provision));
        close_connection(provision_pool, provision);
        return;
    }
    log.debug("Echoed: {s}", .{provision.buffer[0..@intCast(length)]});
    try rt.net.recv(.{
        .socket = provision.socket,
        .buffer = provision.buffer,
        .func = recv_task,
        .ctx = ctx,
    });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();
    const size = 1024;
    var tardy = try Tardy.init(.{
        .allocator = allocator,
        .threading = .single,
    });
    defer tardy.deinit();
    const host = "0.0.0.0";
    const port = 9862;
    const addr = try std.net.Address.parseIp(host, port);
    const socket: std.posix.socket_t = blk: {
        const socket_flags = std.posix.SOCK.STREAM | std.posix.SOCK.CLOEXEC | std.posix.SOCK.NONBLOCK;
        break :blk try std.posix.socket(
            addr.any.family,
            socket_flags,
            std.posix.IPPROTO.TCP,
        );
    };
    if (@hasDecl(std.posix.SO, "REUSEPORT_LB")) {
        try std.posix.setsockopt(
            socket,
            std.posix.SOL.SOCKET,
            std.posix.SO.REUSEPORT_LB,
            &std.mem.toBytes(@as(c_int, 1)),
        );
    } else if (@hasDecl(std.posix.SO, "REUSEPORT")) {
        try std.posix.setsockopt(
            socket,
            std.posix.SOL.SOCKET,
            std.posix.SO.REUSEPORT,
            &std.mem.toBytes(@as(c_int, 1)),
        );
    } else {
        try std.posix.setsockopt(
            socket,
            std.posix.SOL.SOCKET,
            std.posix.SO.REUSEADDR,
            &std.mem.toBytes(@as(c_int, 1)),
        );
    }
    try Cross.socket.to_nonblock(socket);
    try std.posix.bind(socket, &addr.any, addr.getOsSockLen());
    try std.posix.listen(socket, size);
    try tardy.entry(
        struct {
            fn rt_start(rt: *Runtime, alloc: std.mem.Allocator, t_socket: std.posix.socket_t) !void {
                const pool = try Pool(Provision).init(alloc, size, struct {
                    fn init(items: []Provision, all: anytype) void {
                        for (items) |*item| {
                            item.buffer = all.alloc(u8, size) catch unreachable;
                        }
                    }
                }.init, alloc);
                try rt.storage.store_alloc("provision_pool", pool);
                try rt.storage.store_alloc("server_socket", t_socket);
                try rt.net.accept(.{
                    .socket = t_socket,
                    .func = accept_task,
                });
            }
        }.rt_start,
        socket,
        struct {
            fn rt_end(rt: *Runtime, alloc: std.mem.Allocator, _: anytype) void {
                const provision_pool = rt.storage.get_ptr("provision_pool", Pool(Provision));
                provision_pool.deinit(struct {
                    fn pool_deinit(items: []Provision, a: anytype) void {
                        for (items) |item| {
                            a.free(item.buffer);
                        }
                    }
                }.pool_deinit, alloc);
            }
        }.rt_end,
        void,
    );
}`}</code
                    ></pre>
            </section>
            <section class="flex flex-col gap-y-4" id="final-thoughts">
                <h3 class="text-2xl">
                    Final Thoughts <a
                        class="hyper-blue"
                        href="{base}/posts/async-runtime/#final-thoughts">#</a
                    >
                </h3>
                <p>
                    While this style of asynchronous programming isn't as easy to grasp as <code
                        class="language-rust">async/await</code
                    >, it provides the same results while providing more intimate control over what
                    happens where and when. This implementation was tested and is performant,
                    resulting in effectively no performance regression when used in zzz.
                </p>
                <p>
                    It was a pretty meaningful (and useful) library to build and will provide a lot
                    of functionality to both zzz and the Zig ecosystem when it comes to programming
                    in an asynchronous way. It has already enabled the creation of the <a
                        class="hyperlink"
                        href="https://github.com/mookums/zzz/pull/6">async-in-async</a
                    > branch of zzz, allowing for your HTTP handlers to run asynchronously! Hopefully
                    this runtime, now named tardy will help pave the way for future asynchronous libraries
                    to be developed with a shared runtime.
                </p>
            </section>
        </div>
    </div>
</div>
