import pandas as pd
from sqlalchemy import create_engine

conn_string = "postgresql://postgres:Amogh%40250271@localhost/famous_painting"
db = create_engine(conn_string)
conn = db.connect()

files = ['artist','canvas_size','image_link','museum','museum_hours','product_size','subject','work']
for file in files :
    df = pd.read_csv(f"P:/Data Analysis Projects/SQL Case Study/Data/archive/{file}.csv")
    df.to_sql(file, con = conn, if_exists= 'replace', index = False)

