<script lang="ts">
    import { base } from "$app/paths";
    import Header from "$lib/Header.svelte";
    import hljs from "@highlightjs/cdn-assets/highlight.min.js";
    import { onMount } from "svelte";

    onMount(() => {
        hljs.highlightAll();
    });
</script>

<div>
    <Header />
    <div class="flex flex-col items-center w-full">
        <div class="flex flex-col w-full max-w-3xl gap-y-2 px-4">
            <section class="m-4" id="title">
                <hgroup class="flex flex-col justify-center items-center">
                    <h2 class="text-2xl mb-1 font-medium">Statically Analyzing SQL</h2>
                    <span>July 18th, 2025</span>
                </hgroup>
            </section>
            <section class="flex flex-col gap-y-4" id="intro">
                <h3 class="text-2xl">
                    Introduction <a
                        class="hyper-blue"
                        href="{base}/posts/sql-static-analysis/#intro">#</a
                    >
                </h3>
                <p>
                    Recently, I've found myself working a lot with SQL in Rust. I've been using both <a
                        class="hyper-blue"
                        href="https://www.sea-ql.org/SeaORM/">SeaORM</a
                    >
                    and <a class="hyper-blue" href="https://github.com/launchbadge/sqlx">SQLx</a> for
                    my database needs. These two tools provide a lot in terms of query safety and ease
                    of development.
                </p>
                <p>
                    One issue I continually ran into was the need to have a running database during
                    development. This seems like a trivial thing ("<span class="italic"
                        >We're running a database when testing anyways!</span
                    >") but I really think we should have other options for ensuring our queries are
                    safe. I wanted to explore statically analyzing SQL without running a database as
                    a weekend project.
                </p>
            </section>
            <section class="flex flex-col gap-y-4" id="migrations">
                <h3 class="text-2xl">
                    Migrations and State <a
                        class="hyper-blue"
                        href="{base}/posts/sql-static-analysis/#migrations">#</a
                    >
                </h3>
                <p>
                    SQLx handles your query validation in an interesting way that is documented <a
                        class="hyper-blue"
                        href="
                    https://github.com/launchbadge/sqlx/blob/main/FAQ.md#how-do-the-query-macros-work-under-the-hood
                    ">here</a
                    > by the authors better than I could here. The important part is that they rely on
                    the database's frontend to handle the validation for them with the caveat that it
                    requires a database to run.
                </p>
                <p>
                    Our approach requires us to write a database front-end that is able to take in
                    your migrations, manage an internal state, and validate if your queries are
                    valid or invalid (and a handy error message or two would be nice!).
                </p>
                <span>INSERT GRAPHIC HERE</span>
            </section>
            <section class="flex flex-col gap-y-4" id="lexing-parsing">
                <h3 class="text-2xl">
                    Lexing and Parsing <a
                        class="hyper-blue"
                        href="{base}/posts/sql-static-analysis/#lexing-parsing">#</a
                    >
                </h3>
                <p>
                    One of the things that made this possible is the wonderful <a
                        class="hyper-blue"
                        href="https://github.com/apache/datafusion-sqlparser-rs">sqlparser</a
                    > crate made by the folks at Apache. This library allows us to offload the lexing
                    and parsing of the SQL and focus on just walking the AST.
                </p>
                <p>
                    This library allows us to offload the lexing and parsing of the SQL and focus on
                    just walking the AST.
                </p>
            </section>
            <section class="flex flex-col gap-y-4" id="create-table">
                <h3 class="text-2xl">
                    Creating Tables <a
                        class="hyper-blue"
                        href="{base}/posts/sql-static-analysis/#create-table">#</a
                    >
                </h3>
                <p>
                    The first thing you do in your SQL database is create the tables that represent
                    your data so this was a natural first step. When you see the query below, what
                    are all of the pieces that are important for us?
                </p>
                <span
                    >IMAGE HERE OF "create table account (id int primary key, name text not null,
                    status int not null default 1, email text not null, unique(email))"
                </span>
                <p>
                    The first and easiest thing to notice is that the name has a name, "account".
                    This table name serves as an identifier for the underlying table, meaning we can
                    reference this table in other SQL statements thorugh this name.
                </p>

                <pre><code
                        >{`pub struct Simulator {
    // Mapping of the table's name to the Table.
    pub tables: HashMap<String, Table>
}`}</code
                    ></pre>
                <p>
                    The next thing you notice is the list of the columns that belong to this table.
                    Each of these columns has a type and a set of constraints. There are a couple
                    differnet constraints that can exist on these columns but for now, we will focus
                    on just <code>not null</code> and <code>default</code>. We will worry about
                    others, like "primary key", later on.
                </p>
                <p>
                    We can define some basic structures for <code>SqlType</code> and
                    <code>Column</code> for representing the types and the columns respectively.
                </p>
                <pre><code
                        >{`pub enum SqlType {
    /// 16 bit Signed Integer
    SmallInt,
    /// 32 bit Signed Integer
    Integer,
    /// 64 bit Signed Integer,
    BigInt,

    /// 32 bit Floating
    Float,
    /// 64 bit Floating
    Double,

    /// String
    Text,

    Boolean,
    Unknown(String),
}


pub struct Column {
    // The type of the column like SqlType::Text
    pub ty: SqlType,
    // If the column can be NULL.
    pub nullable: bool,
    // If the column has a DEFAULT defined.
    pub default: bool,
}

// We can now define the Table.
pub struct Table {
    pub columns: HashMap<String, Column>,
}

`}</code
                    >
            </pre>
            </section>
        </div>
    </div>
</div>
