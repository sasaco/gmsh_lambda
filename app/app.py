import json
import gmsh

def handler(event, context):

    temp_input_path = 'temp.geo'
    temp_output_path = 'temp.msh'

    js = json.loads(context, object_pairs_hook=dict)
    fout=open(temp_input_path, 'w')
    print(js['geo'], file=fout)
    fout.close()


    gmsh.initialize()
    gmsh.open(temp_input_path)
    gmsh.model.mesh.generate(js['dim'])
    gmsh.write(temp_output_path)
    gmsh.clear()
    gmsh.finalize()


    f = open(temp_output_path)
    msh = f.read()  # ファイル終端まで全て読んだデータを返す
    f.close()


    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "msh": msh,
            }
        ),
    }