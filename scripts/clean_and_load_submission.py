import pandas as pd
from sqlalchemy import create_engine, text
from sqlalchemy.types import String, Integer
from urllib.parse import quote_plus

MYSQL_USER = "root"
MYSQL_PASSWORD = "your_password_here"
MYSQL_HOST = "localhost"
MYSQL_PORT = 3306
MYSQL_DB = "roblox_workforce_db"
DATA_DIR = "."

MYSQL_PASSWORD_ENCODED = quote_plus(MYSQL_PASSWORD)

employee = pd.read_excel(f"{DATA_DIR}/employee_dataset.xlsx")
department = pd.read_excel(f"{DATA_DIR}/Department.xlsx")
education = pd.read_excel(f"{DATA_DIR}/Education.xlsx")
finance = pd.read_excel(f"{DATA_DIR}/finance_dataset.xlsx")
emp_performance = pd.read_excel(f"{DATA_DIR}/employee_performance.xlsx")
health = pd.read_excel(f"{DATA_DIR}/health_dataset.xlsx")
dept_performance = pd.read_excel(f"{DATA_DIR}/department_performance.xlsx")

print("Raw row counts:")
for name, df in [("employee", employee), ("department", department),
                  ("education", education), ("finance", finance),
                  ("emp_performance", emp_performance), ("health", health),
                  ("dept_performance", dept_performance)]:
    print(f"  {name}: {len(df)}")

before = len(employee)
employee = employee.drop_duplicates(subset="EmployeeID", keep="first").copy()
print(f"\nEmployee: dropped {before - len(employee)} duplicate rows")

employee.loc[employee.EmployeeID == 279, "Age"] = 48
employee.loc[employee.EmployeeID == 21187, "Age"] = 30

missing_gender_ids = [4470, 5826, 9301, 12333, 19342, 25405, 26938]
employee.loc[employee.EmployeeID.isin(missing_gender_ids), "Gender"] = "Female"
employee.loc[employee.Gender == "Femal", "Gender"] = "Female"

employee.loc[employee.EmployeeID == 25142, "Department Code"] = "FIN"
employee.loc[employee.EmployeeID == 28686, "Last Name"] = "Campbell"

employee["Phone Number"] = employee["Phone Number"].astype(object)
phone_fixes = {
    3257: "233590129809",
    14367: "233556780467",
    17803: "233500129809",
    17986: "233500012987",
    21281: "233260125678",
    23486: "233530895670",
    28940: "233540122309",
}
for emp_id, phone in phone_fixes.items():
    employee.loc[employee.EmployeeID == emp_id, "Phone Number"] = phone

employee["employee_status"] = employee["employee_status"].fillna("Active")

def clean_phone(val):
    if pd.isna(val):
        return None
    if isinstance(val, str):
        return val
    return str(int(round(float(val))))

employee["Phone Number"] = employee["Phone Number"].apply(clean_phone)

employee["Date Joined"] = pd.to_datetime(
    employee["Date Joined"], unit="D", origin="1899-12-30"
).dt.date

check_cols = ["Age", "Gender", "Department Code", "Last Name", "Phone Number", "employee_status"]
remaining_missing = employee[check_cols].isna().sum()
print("\nEmployee - remaining missing values after cleaning (should all be 0):")
print(remaining_missing)

before = len(education)
education = education.drop_duplicates(subset="employee_id", keep="first").copy()
print(f"\nEducation: dropped {before - len(education)} duplicate rows")

server_engine = create_engine(f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD_ENCODED}@{MYSQL_HOST}:{MYSQL_PORT}")
with server_engine.connect() as conn:
    conn.execute(text(f"DROP DATABASE IF EXISTS {MYSQL_DB}"))
    conn.execute(text(f"CREATE DATABASE {MYSQL_DB}"))
    conn.commit()

engine = create_engine(
    f"mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD_ENCODED}@{MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}"
)

tables = {
    "department": department,
    "employee": employee,
    "education": education,
    "health": health,
    "finance": finance,
    "employee_performance": emp_performance,
    "department_performance": dept_performance,
}

key_column_dtypes = {
    "department": {"department_code": String(10), "department_name": String(100)},
    "employee": {"Department Code": String(10)},
    "department_performance": {"Department": String(100)},
}

for table_name, df in tables.items():
    dtype = key_column_dtypes.get(table_name)
    df.to_sql(table_name, engine, if_exists="replace", index=False, dtype=dtype)
    print(f"Loaded '{table_name}' -> {len(df)} rows")

print("\nAll 7 tables cleaned and loaded into MySQL database:", MYSQL_DB)
