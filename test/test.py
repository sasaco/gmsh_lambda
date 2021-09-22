import json
import gmsh

def read_file(fnameR='test/test.json'):
    f = open(fnameR)
    fstr = f.read()  # ファイル終端まで全て読んだデータを返す
    f.close()
    return fstr

def write_file(out_text, fnameR='test/test.out.json'):
    fout=open(fnameR, 'w')
    print(out_text, file=fout)
    fout.close()


temp_input_path = 'app/temp.geo'
temp_output_path = 'app/temp.msh'

js = json.loads(read_file(), object_pairs_hook=dict)
write_file(js['geo'], temp_input_path)


gmsh.initialize()
gmsh.open(temp_input_path)
gmsh.model.mesh.generate(js['dim'])
gmsh.write(temp_output_path)
gmsh.clear()
gmsh.finalize()


msh = read_file(temp_output_path)
write_file(json.dumps({'msh': msh}))
