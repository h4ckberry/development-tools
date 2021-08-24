#! /usr/bin/python
import sys
import datetime
import random, string
import json
import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

def random_key(n):
   return ''.join(random.choices(string.ascii_letters + string.digits, k=n))

def load_json(json_data):
    json_open = open(json_data, 'r')
    json_load = json.load(json_open)
    json_list = [data for data in json_load]
    return json_list

def add_data(db, collection_name, json_path, uid, key_len):
    json_list = load_json(json_path)
    [input_data.update({uid: random_key(key_len)}) for input_data in json_list]

    doc_ref = db.collection(collection_name)
    [doc_ref.document(input_data[uid]).set(input_data) for input_data in json_list]


if __name__ == '__main__':
    args = sys.argv

    if 6 == len(args):

        credential_path = args[1]
        collection_name = args[2]
        json_path = args[3]
        uid = args[4]
        key_len = int(args[5])
        
        sys.stderr.write("*** 開始 ***\n")

        try:
            cred = credentials.Certificate(credential_path)
            firebase_admin.initialize_app(cred)
            db = firestore.client()
            add_data(db, collection_name, json_path, uid, key_len)

        except Exception as ee:
            sys.stderr.write("*** error *** in firestore.Client ***\n")
            sys.stderr.write(str(ee) + "\n")

        sys.stderr.write("*** 終了 ***\n")
                
    elif (6 > len(args)) :
         print('Arguments are too short')
    else:
        print('Arguments are too long')