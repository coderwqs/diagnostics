import sqlite3
from datetime import datetime

import scipy.io
import pandas as pd
import json

def load_mat(file_path: str):
    dic = scipy.io.loadmat(file_path)
    speed_key = list(dic.keys())[5]
    speed = dic[speed_key][0][0]
    var = list(dic.keys())[3]
    con_list = [[element for element in upperElement] for upperElement in dic[var]]
    df = pd.DataFrame(con_list)
    return df[0].tolist(), int(speed)

def insert_data_to_db(device_id: str, data: list, speed: int, sampling_rate: float):
    # Connect to SQLite database
    conn = sqlite3.connect('/home/coderwqs/workspace/flutter/diagnostics/.dart_tool/sqflite_common_ffi/databases/app.db')
    cursor = conn.cursor()

    # Current timestamp
    created_at = int(datetime.now().timestamp())

    # 将数据转换为JSON字符串
    data_json = json.dumps(data[:100])

    # 插入完整的JSON数据
    cursor.execute('''
        INSERT INTO history (deviceId, dataTime, samplingRate, rotationSpeed, data, createdAt)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (device_id, created_at, sampling_rate, speed, data_json, created_at))

    # Commit changes and close connection
    conn.commit()
    conn.close()

if __name__ == '__main__':
    path = '/py-case/mat-reader/base_file/122.mat'
    device_id = '9c5f2096-e2e4-484e-a8a3-da1ecd4d12e2'  # Replace with actual device ID
    sampling_rate = 48000.0  # Replace with actual sampling rate if needed

    data, speed = load_mat(path)
    insert_data_to_db(device_id, data, speed, sampling_rate)