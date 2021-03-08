# -*- coding: utf-8 -*-
"""
Created on Wed Feb 22 21:40:30 2017

@author: Jie Hou
"""
import os
import numpy as np

def chkdirs(fn):
  dn = os.path.dirname(fn)
  if not os.path.exists(dn): os.makedirs(dn)



def import_SVM(filename, delimiter=' ', delimiter2=' ',comment='#',skiprows=0, start=0, end = 0,target_col = 1, dtype=np.float32):
    # Open a file
    file = open(filename, "r")
    #print "Name of the file: ", file.name
    if skiprows !=0:
       dataset = file.read().splitlines()[skiprows:]
    if skiprows ==0 and start ==0 and end !=0:
       dataset = file.read().splitlines()[0:end]
    if skiprows ==0 and start !=0:
       dataset = file.read().splitlines()[start:]
    if skiprows ==0 and start !=0 and end !=0:
       dataset = file.read().splitlines()[start:end]
    else:
       dataset = file.read().splitlines()
    #print dataset
    newdata = []
    for i in range(0,len(dataset)):
        line = dataset[i]
        if line[0] != comment:
           temp = line.split(delimiter,target_col)
           feature = temp[target_col]
           label = temp[0]
           if label == 'N':
               label = 0
           fea = feature.split(delimiter2)
           newline = []
           newline.append(label)
           for j in range(0,len(fea)):
               if fea[j][0] == '#' :
                   continue
               if fea[j].find(':') >0 :
                   (num,val) = fea[j].split(':')
                   newline.append(float(val))
            
           newdata.append(newline)
    data = np.array(newdata, dtype=dtype)
    file.close()
    return data



def import_SVM_by_target(filename, delimiter=' ', delimiter2=' ',comment='#',skiprows=0, start=0, end = 0,target_col = 1, dtype=np.float32):
    # Open a file
    file = open(filename, "r")
    #print "Name of the file: ", file.name
    if skiprows !=0:
       dataset = file.read().splitlines()[skiprows:]
    if skiprows ==0 and start ==0 and end !=0:
       dataset = file.read().splitlines()[0:end]
    if skiprows ==0 and start !=0:
       dataset = file.read().splitlines()[start:]
    if skiprows ==0 and start !=0 and end !=0:
       dataset = file.read().splitlines()[start:end]
    else:
       dataset = file.read().splitlines()
    #print dataset
    data_all_dict=dict()
    newdata = []
    for i in range(0,len(dataset)):
        line = dataset[i]
        if line[0] != comment:
           temp = line.split(delimiter,target_col)
           feature = temp[target_col]
           label = temp[0]
           if label == 'N':
               label = 0
           fea = feature.split(delimiter2)
           newline = []
           newline.append(label)
           for j in range(0,len(fea)):
               if fea[j][0] == '#' : ##T0387:Pcons_local_TS3
                   (tar,mod) = fea[j].split(':')
                   if tar in data_all_dict:
                        data_all_dict[tar].append(newline)
                   else:
                        data_all_dict[tar]=[]
                        data_all_dict[tar].append(newline)
                   break
               if fea[j].find(':') >0 :
                   (num,val) = fea[j].split(':')
                   newline.append(float(val))
            
           #newdata.append(newline)          
    # list(data_all_dict.keys()).
    for key in data_all_dict.keys():
          myarray = np.array(data_all_dict[key], dtype=dtype)
          data_all_dict[key] = myarray
          print "keys: ", key, " shape: ", data_all_dict[key].shape
    
    file.close()
    return data_all_dict
