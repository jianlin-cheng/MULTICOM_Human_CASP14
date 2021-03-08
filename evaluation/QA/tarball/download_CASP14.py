import os

def download_models():
    for line in open("targets.txt"):
        line = line.strip()
        os.system("wget http://www.predictioncenter.org/download_area/CASP14/server_predictions/"+line+".3D.srv.tar.gz")
        os.system("tar -zxvf " + line + ".3D.srv.tar.gz")

download_models()