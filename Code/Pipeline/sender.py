#!/usr/bin/env python3
# http://weifan-tmm.blogspot.kr/2015/07/a-simple-turorial-for-python-c-inter.html
import sysv_ipc
import numpy as np
import struct
import scipy.sparse as sps

BUFF_SIZE = 400000

from type_definitions import *

if __name__ == '__main__':
    msg_string = "sample t\0"

    msg_double2 = 9876.12345
    msg_npy = np.arange(BUFF_SIZE, dtype=np.uint8).reshape((2,BUFF_SIZE//2))
    msg_npy_half = np.arange(BUFF_SIZE//2, dtype=np.uint8).reshape((2,BUFF_SIZE//4))
    m1 = 20000
    #m2 = 20000
    n = 20000
    #print(msg_npy)
    T1 = sps.random(m1, n, density=0.001, format='coo',dtype=np.uint8)
    values = T1.data
    valuesAdresses = values.__array_interface__['data'][0]
    size = values.__array_interface__['shape'][0]
    print(values.__array_interface__['data'][0])
    col = np.array(T1.col)
    row = np.array(T1.row)
    msg_double1 = len(values.tobytes())

    #T2 = sps.random(n, m2, density=0.001, format='csr')
    #T1 = T1.dot(T1.dot(T1))
    #T2 = T2.dot(T2)
    #T1_size = (T1.data.nbytes + T1.indptr.nbytes + T1.indices.nbytes)/1000000000
    #T2_size = (T1.data.nbytes + T1.indptr.nbytes + T1.indices.nbytes)/1000000000

    #frag = ((T1_size+T2_size)/8)*(np.mean([m1,m2,n]))
    try:
        mq = sysv_ipc.MessageQueue(12345, sysv_ipc.IPC_CREAT)

        # string transmission
        # mq.send(msg_string, True, type=TYPE_STRING)
        # print(f"string sent: {msg_string}")

        # # Two double transmission
        bytearray1 = struct.pack("d", valuesAdresses)
        bytearray2 = struct.pack("d", size)
        mq.send(bytearray1+bytearray2, True, type=TYPE_TWODOUBLES)
        print(f"two int sent: {msg_double1}, {msg_double2}")
        for i in range(10):
            print(values[i])

        # # numpy array transmission
        #print(msg_npy)
        #mq.send(msg_npy.tobytes(order='C'), True, type=TYPE_NUMPY)
        # print(f"numpy array sent: {msg_npy}")

        # one double one numpy transmission
        #bytearray1 = struct.pack("d", msg_double1)
        #mq.send(bytearray1 + values.tobytes(order='C'), True, type=TYPE_DOUBLEANDNUMPY)

        #print(len(values.tobytes()))
        #print(values)
        #mq.send(values.tobytes(order='C'), True, type=TYPE_NUMPY)
        #mq.send(col.tobytes(order='C'), True, type=TYPE_NUMPY)
        #mq.send(row.tobytes(order='C'), True, type=TYPE_NUMPY)
        #print(f"one double and numpy array sent: {msg_double1}, {msg_npy_half}")


    except sysv_ipc.ExistentialError:
        print("ERROR: message queue creation failed")


