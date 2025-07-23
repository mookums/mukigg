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
        <div class="flex flex-col w-full max-w-3xl gap-y-4 px-4">
            <section class="m-4" id="title">
                <hgroup class="flex flex-col justify-center items-center">
                    <h2 class="text-2xl mb-1 font-medium">
                        Statically Analyzing SQL: Introduction
                    </h2>
                    <span>July 18th, 2025</span>
                </hgroup>
            </section>
            <p class="text-center">
                This is a multi-part series. If you want to play around with a live demo, you can
                try it out
                <a class="hyper-blue" href="{base}/demo/truffle">here</a>. You can also view the
                source code
                <a class="hyper-blue" href="https://github.com/mookums/truffle">here</a>.
            </p>
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
                    and <a class="hyper-blue" href="https://github.com/launchbadge/sqlx">SQLx</a>
                    for my database needs. These two tools provide a lot in terms of query safety and
                    ease of development.
                </p>
                <p>
                    One issue I continually ran into was the need to have a running database during
                    development. This seems like a trivial thing ("<span class="italic"
                        >We're running a database when testing anyways!</span
                    >") but I really think we should have other options for ensuring our queries are
                    safe. I wanted to explore statically analyzing SQL without running a database.
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
                    Our approach requires us to write a program that is able to take in your
                    migrations, manage an internal state, and validate if your queries are valid or
                    invalid (plus, a handy error message or two would be nice!).
                </p>
                <p>This approach that I will be covering is not good for cases where you:</p>
                <ul class="list-disc ml-[1rem]">
                    <li>directly modify the schema of your DB without a migration.</li>
                    <li>load and utilize extensions.</li>
                    <li>
                        want to use an SQL feature that is specific to your DB/not yet supported in
                        this tool.
                    </li>
                </ul>
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
                    your data. When you see the query below, what are all of the pieces that are
                    important for us?
                </p>
                <span
                    >IMAGE HERE OF "create table account (id int primary key, name text not null,
                    status int not null default 1, email text not null, unique(email))"
                </span>
                <p>
                    The first and easiest thing to notice is that the name has a name, "account".
                    This table name serves as an identifier, allowing us to reference this table in
                    other SQL statements.
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
                    different constraints that can exist on these columns but for now, we will focus
                    on just <code>not null</code> and <code>default</code>. We will handle others,
                    like "primary key", later on.
                </p>
                <p>
                    We can define some basic structures for <code>SqlType</code> and
                    <code>Column</code> for representing the types and the columns respectively. These
                    are fairly minimal for now.
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
}`}</code
                    ></pre>
                <p>
                    We can now actually create the table and store it within the <code
                        >Simulator</code
                    > instance.
                </p>
            </section>
            <section class="flex flex-col gap-y-4" id="validation">
                <h3 class="text-2xl">
                    Validation <a
                        class="hyper-blue"
                        href="{base}/posts/sql-static-analysis/#validation">#</a
                    >
                </h3>
                <p>
                    There are some low hanging validations we can do now that we are building up our
                    state. One of these is ensuring that there can't be two tables with the same
                    name. We start off by defining an Error type for our Simulator.
                </p>
                <pre><code
                        >{`#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("Parsing: {0}")]
    Parsing(#[from] sqlparser::parser::ParserError),
    #[error("Table '{0}' already exists")]
    TableAlreadyExists(String),
    #[error("'{0}' is currently unsupported")]
    Unsupported(String),
}`}</code
                    ></pre>
                <p>
                    Now that we have defined an error type, with a variant to use for this case, we
                    can actually do our validation check.
                </p>
                <pre><code
                        >{`// Ensure that this table doesn't already exist.
if !create_table.if_not_exists && self.tables.contains_key(&name) {
    return Err(Error::TableAlreadyExists(name));
}`}
            </code></pre>
                <p>
                    Since SQL <code>CREATE TABLE</code> statements can include an optional
                    <code>IF NOT EXISTS</code>, we must check that along with ensuring that this
                    table doesn't currently exist.
                </p>
            </section>
            <section class="flex flex-col gap-y-4" id="create-column">
                <h3 class="text-2xl">
                    Creating Columns <a
                        class="hyper-blue"
                        href="{base}/posts/sql-static-analysis/#create-column">#</a
                    >
                </h3>
                <p>
                    After that, we can start loading our columns into this table. We can start off
                    on a naive implementation that just creates a column and ignores constraints.
                </p>
                <pre><code
                        >{`let mut table = Table::default();
for column in create_table.columns {
    let column_name = &column.name.value;
    let mut nullable = true;
    let mut default = false;
    let ty: SqlType = column.data_type.into();

    let col = Column { ty, nullable, default };

    // TODO: Check nullability, default, and constraints.

    // Ensure that this column doen't already exist.
    if table.columns.contains_key(column_name) {
        return Err(Error::ColumnAlreadyExists(column_name.to_string()));
    }

    table.columns.insert(column_name.to_string(), col);
}`}</code
                    ></pre>
                <p>
                    This snippet above also adds another validation, ensuring that we don't have two
                    columns of the same name within a Table.
                </p>
                <p>
                    So far, we have properly created a Simulator that has accurate state regarding
                    the executed queries and is able to do some basic validations. In the next post,
                    we will handle the column and table level constraints.
                </p>
            </section>
        </div>
    </div>
</div>
