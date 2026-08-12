import streamlit as st
import pandas as pd
import plotly.express as px
from sqlalchemy import create_engine

MYSQL_USER = "root"
MYSQL_PASSWORD = "your_password"
MYSQL_HOST = "localhost"
MYSQL_PORT = 3306
MYSQL_DB = "roblox_workforce_db"

engine = create_engine(f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}")

@st.cache_data
def load_data():
    queries = {
        'composition': "SELECT * FROM vw_workforce_composition",
        'compensation': "SELECT * FROM vw_education_vs_compensation",
        'cost': "SELECT * FROM vw_compensation_by_department",
        'performance': "SELECT * FROM vw_department_performance_summary",
        'health': "SELECT * FROM vw_health_risk"
    }
    data = {}
    for name, query in queries.items():
        data[name] = pd.read_sql(query, engine)
    return data

data = load_data()

st.set_page_config(page_title="Roblox Workforce Analytics", layout="wide")
st.title("👥 Roblox Africa - Workforce Analytics Dashboard")

col1, col2, col3, col4 = st.columns(4)
with col1:
    st.metric("Total Employees", f"{data['composition']['headcount'].sum():,}")
with col2:
    st.metric("Average Age", f"{data['composition']['avg_age'].mean():.1f}")
with col3:
    st.metric("Departments", len(data['performance']['department_name'].unique()))
with col4:
    st.metric("Total Compensation", f"${data['cost']['total_compensation_cost'].sum():,.0f}")

st.subheader("Headcount by Department")
fig = px.bar(data['composition'].groupby('department_name')['headcount'].sum().reset_index(), 
             x='department_name', y='headcount', color='department_name')
st.plotly_chart(fig, use_container_width=True)

st.subheader("Compensation Analysis")
fig2 = px.bar(data['cost'], x='department_name', y='avg_basic_salary', color='department_name')
st.plotly_chart(fig2, use_container_width=True)

st.subheader("Department Performance")
fig3 = px.bar(data['performance'], x='department_name', y='Average_Performance_Score', color='department_name')
st.plotly_chart(fig3, use_container_width=True)

st.subheader("Health Risk Overview")
fig4 = px.pie(data['health'].groupby('Insurance_status')['employee_count'].sum().reset_index(), 
              values='employee_count', names='Insurance_status')
st.plotly_chart(fig4, use_container_width=True)
