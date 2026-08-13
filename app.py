import streamlit as st
import pandas as pd

from sqlalchemy import create_engine, text


# ============================================================
# CONFIGURATION
# ============================================================

APP_NAME = "My NewSQL Retail System"

DATABASE_URL = (
    "cockroachdb://root@127.0.0.1:26257/"
    "defaultdb?sslmode=disable"
)


st.set_page_config(
    page_title=APP_NAME,
    page_icon="🛒",
    layout="wide"
)

st.title("🛒 " + APP_NAME)

st.caption(
    "Streamlit + Python + CockroachDB"
)


# ============================================================
# DATABASE CONNECTION
# ============================================================

@st.cache_resource
def get_engine():

    return create_engine(
        DATABASE_URL,
        pool_pre_ping=True
    )


engine = get_engine()


# ============================================================
# CREATE DATABASE TABLES
# ============================================================

def initialize_database():

    with engine.begin() as conn:

        conn.execute(
            text("""
                CREATE TABLE IF NOT EXISTS orders
                (
                    order_id UUID
                        PRIMARY KEY
                        DEFAULT gen_random_uuid(),

                    customer_name STRING
                        NOT NULL,

                    product_name STRING
                        NOT NULL,

                    quantity INT
                        NOT NULL,

                    unit_price DECIMAL(12,2)
                        NOT NULL,

                    status STRING
                        DEFAULT 'Pending',

                    created_at TIMESTAMPTZ
                        DEFAULT current_timestamp()
                )
            """)
        )


        conn.execute(
            text("""
                CREATE TABLE IF NOT EXISTS accounts
                (
                    account_id INT
                        PRIMARY KEY,

                    account_name STRING
                        NOT NULL,

                    balance DECIMAL(12,2)
                        NOT NULL
                        CHECK (balance >= 0)
                )
            """)
        )


        conn.execute(
            text("""
                INSERT INTO accounts
                VALUES
                    (1, 'Account A', 1000),
                    (2, 'Account B', 500)

                ON CONFLICT (account_id)
                DO NOTHING
            """)
        )


initialize_database()


# ============================================================
# MENU
# ============================================================

tab1, tab2, tab3, tab4 = st.tabs(
    [
        "📊 Dashboard",
        "➕ Add Order",
        "✏️ Manage Orders",
        "💰 Transaction"
    ]
)


# ============================================================
# DASHBOARD
# ============================================================

with tab1:

    st.header("Dashboard")

    query = """
        SELECT
            order_id,
            customer_name,
            product_name,
            quantity,
            unit_price,
            quantity * unit_price AS revenue,
            status,
            created_at
        FROM orders

        ORDER BY created_at DESC
    """

    df = pd.read_sql(
        query,
        engine
    )


    if df.empty:

        st.info(
            "No data yet. Create your first order."
        )

    else:

        col1, col2, col3 = st.columns(3)

        col1.metric(
            "Orders",
            len(df)
        )

        col2.metric(
            "Quantity",
            int(df["quantity"].sum())
        )

        col3.metric(
            "Revenue",
            f"${float(df['revenue'].sum()):,.2f}"
        )


        st.dataframe(
            df,
            use_container_width=True
        )


        chart_df = (
            df
            .groupby(
                "product_name",
                as_index=False
            )["revenue"]
            .sum()
        )


        st.subheader(
            "Revenue by Product"
        )

        st.bar_chart(
            chart_df,
            x="product_name",
            y="revenue"
        )


# ============================================================
# INSERT
# ============================================================

with tab2:

    st.header(
        "Create New Order"
    )


    customer = st.text_input(
        "Customer Name"
    )

    product = st.text_input(
        "Product Name"
    )

    quantity = st.number_input(
        "Quantity",
        min_value=1,
        value=1
    )

    unit_price = st.number_input(
        "Unit Price",
        min_value=0.0,
        value=100.0
    )


    if st.button(
        "Create Order",
        type="primary"
    ):

        if not customer.strip():

            st.error(
                "Please enter customer name."
            )

        elif not product.strip():

            st.error(
                "Please enter product name."
            )

        else:

            with engine.begin() as conn:

                conn.execute(
                    text("""
                        INSERT INTO orders
                        (
                            customer_name,
                            product_name,
                            quantity,
                            unit_price
                        )

                        VALUES
                        (
                            :customer,
                            :product,
                            :quantity,
                            :price
                        )
                    """),

                    {
                        "customer": customer,
                        "product": product,
                        "quantity": int(quantity),
                        "price": float(unit_price)
                    }
                )


            st.success(
                "Order created successfully!"
            )


# ============================================================
# UPDATE / DELETE
# ============================================================

with tab3:

    st.header(
        "Manage Orders"
    )


    orders = pd.read_sql(
        """
        SELECT
            order_id,
            customer_name,
            product_name,
            status
        FROM orders

        ORDER BY created_at DESC
        """,
        engine
    )


    if orders.empty:

        st.info(
            "No orders available."
        )

    else:

        order_id = st.selectbox(
            "Select Order",
            orders["order_id"].astype(str)
        )


        status = st.selectbox(
            "Status",
            [
                "Pending",
                "Paid",
                "Shipped",
                "Completed",
                "Cancelled"
            ]
        )


        col1, col2 = st.columns(2)


        with col1:

            if st.button(
                "Update Status"
            ):

                with engine.begin() as conn:

                    conn.execute(
                        text("""
                            UPDATE orders

                            SET status = :status

                            WHERE order_id = :order_id
                        """),

                        {
                            "status": status,
                            "order_id": order_id
                        }
                    )


                st.success(
                    "Order updated!"
                )


        with col2:

            if st.button(
                "Delete Order"
            ):

                with engine.begin() as conn:

                    conn.execute(
                        text("""
                            DELETE FROM orders

                            WHERE order_id = :order_id
                        """),

                        {
                            "order_id": order_id
                        }
                    )


                st.success(
                    "Order deleted!"
                )


# ============================================================
# ACID TRANSACTION
# ============================================================

with tab4:

    st.header(
        "ACID Transaction Demo"
    )


    accounts = pd.read_sql(
        """
        SELECT *
        FROM accounts
        ORDER BY account_id
        """,
        engine
    )


    st.dataframe(
        accounts,
        use_container_width=True
    )


    amount = st.number_input(
        "Transfer Amount",
        min_value=1.0,
        value=100.0
    )


    simulate_error = st.checkbox(
        "Simulate failure"
    )


    if st.button(
        "Transfer A → B",
        type="primary"
    ):

        try:

            with engine.begin() as conn:

                result = conn.execute(
                    text("""
                        UPDATE accounts

                        SET balance =
                            balance - :amount

                        WHERE account_id = 1
                          AND balance >= :amount
                    """),

                    {
                        "amount": amount
                    }
                )


                if result.rowcount != 1:

                    raise ValueError(
                        "Insufficient balance."
                    )


                if simulate_error:

                    raise RuntimeError(
                        "Simulated system failure!"
                    )


                conn.execute(
                    text("""
                        UPDATE accounts

                        SET balance =
                            balance + :amount

                        WHERE account_id = 2
                    """),

                    {
                        "amount": amount
                    }
                )


            st.success(
                "COMMIT: Transfer successful."
            )


        except Exception as e:

            st.error(
                f"ROLLBACK: {e}"
            )