import streamlit as st
import pandas as pd
import mysql.connector

# ---------------- DATABASE CONNECTION ----------------

conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="Your_Password",
    database="tenant_System1"
)

# ---------------- PAGE CONFIG ----------------

st.set_page_config(
    page_title="Tenant Management System",
    layout="wide"
)

st.title("🏠 Tenant Management System")

# ---------------- DASHBOARD SELECTION ----------------

dashboard = st.sidebar.radio(
    "Choose Dashboard",
    ["Landlord", "Tenant"]
)

# =====================================================
# LANDLORD DASHBOARD
# =====================================================

if dashboard == "Landlord":

    st.header("👨‍💼 Landlord Dashboard")

    tab1, tab2, tab3 = st.tabs(
        ["Properties", "Payments", "Analytics"]
    )

    # ---------------- PROPERTIES ----------------

    with tab1:

        st.subheader("Property Details")

        query = """
        SELECT
            P_Id,
            Address,
            Capacity,
            Rent_amount,
            Availability_status
        FROM Property
        """

        df = pd.read_sql(query, conn)

        st.dataframe(df, use_container_width=True)

    # ---------------- PAYMENTS ----------------

    with tab2:

        st.subheader("Tenant Payments")

        query = """
        SELECT
            CONCAT(U.FName,' ',U.LName) AS Tenant_Name,
            P.Address,
            Pay.Amount,
            Pay.Status,
            Pay.Rent_Month,
            Pay.Payment_date
        FROM Payment Pay
        JOIN Users U
        ON Pay.Tenant_id = U.User_id
        JOIN Property P
        ON Pay.P_Id = P.P_Id
        ORDER BY Pay.Rent_Month DESC
        """

        df = pd.read_sql(query, conn)

        st.dataframe(df, use_container_width=True)

    # ---------------- ANALYTICS ----------------

    with tab3:

        st.subheader("Rent Collection Analytics")

        query = """
        SELECT
            P.Address,
            SUM(Pay.Amount) AS Total_Rent
        FROM Payment Pay
        JOIN Property P
        ON Pay.P_Id = P.P_Id
        WHERE Pay.Status='Paid'
        GROUP BY P.Address
        """

        analytics_df = pd.read_sql(query, conn)

        if not analytics_df.empty:

            st.bar_chart(
                analytics_df.set_index("Address")
            )

            total = analytics_df["Total_Rent"].sum()

            st.metric(
                "Total Rent Collected",
                f"₹{int(total):,}"
            )

        else:

            st.warning("No paid rent records found.")

# =====================================================
# TENANT DASHBOARD
# =====================================================

else:

    st.header("👨‍🎓 Tenant Dashboard")

    tenant_id = st.number_input(
        "Enter Tenant ID",
        min_value=1,
        step=1,
        value=2
    )

    tab1, tab2 = st.tabs(
        ["My Property", "My Payments"]
    )

    # ---------------- MY PROPERTY ----------------

    with tab1:

        st.subheader("Allocated Property")

        query = f"""
        SELECT
            CONCAT(U.FName,' ',U.LName) AS Tenant_Name,
            P.Address,
            P.Rent_amount,
            A.Checkin_date,
            A.Leased_time
        FROM Allocated_To A
        JOIN Property P
        ON A.P_Id = P.P_Id
        JOIN Users U
        ON A.Tenant_id = U.User_id
        WHERE A.Tenant_id = {tenant_id}
        """

        df = pd.read_sql(query, conn)

        if not df.empty:
            st.dataframe(df, use_container_width=True)
        else:
            st.warning("No property allocated.")

    # ---------------- MY PAYMENTS ----------------

    with tab2:

        st.subheader("Payment History")

        query = f"""
        SELECT
            Amount,
            Status,
            Rent_Month,
            Payment_date
        FROM Payment
        WHERE Tenant_id = {tenant_id}
        ORDER BY Rent_Month DESC
        """

        df = pd.read_sql(query, conn)

        if not df.empty:
            st.dataframe(df, use_container_width=True)

            paid = len(
                df[df["Status"] == "Paid"]
            )

            pending = len(
                df[df["Status"] == "Pending"]
            )

            col1, col2 = st.columns(2)

            with col1:
                st.metric("Paid Payments", paid)

            with col2:
                st.metric("Pending Payments", pending)

        else:
            st.warning("No payment records found.")

# ---------------- CLOSE CONNECTION ----------------

conn.close()
