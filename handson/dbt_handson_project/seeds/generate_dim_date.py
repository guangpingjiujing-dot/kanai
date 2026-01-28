import csv
from datetime import datetime, timedelta

start_date = datetime(2020, 1, 1)
end_date = datetime(2030, 12, 31)
days_of_week = ['月', '火', '水', '木', '金', '土', '日']

with open('dim_date_seed.csv', 'w', encoding='utf-8', newline='') as f:
    writer = csv.writer(f)
    writer.writerow(['date_key', 'date_value', 'year', 'month', 'day', 'quarter', 'day_of_week'])
    
    current = start_date
    while current <= end_date:
        date_key = int(current.strftime('%Y%m%d'))
        year = current.year
        month = current.month
        day = current.day
        quarter = (month - 1) // 3 + 1
        day_of_week = days_of_week[current.weekday()]
        
        writer.writerow([date_key, current.strftime('%Y-%m-%d'), year, month, day, quarter, day_of_week])
        current += timedelta(days=1)
