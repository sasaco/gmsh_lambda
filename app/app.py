import json
import gmsh

def handler(event, context):

    temp_input_path = 'temp.geo'
    temp_output_path = 'temp.msh'

    # 引数
    geo = event['geo']
    dim = event['dim']

    # geo ファイルを 書き込む
    fout=open(temp_input_path, 'w')
    print(geo, file=fout)
    fout.close()

    # gmsh で メッシュを作成し、msh ファイルを 書き込む
    gmsh.initialize()
    gmsh.open(temp_input_path)
    gmsh.model.mesh.generate(dim)
    gmsh.write(temp_output_path)
    gmsh.clear()
    gmsh.finalize()

    # 書き込んだ msh ファイルを 読み込む
    f = open(temp_output_path)
    msh = f.read()  # ファイル終端まで全て読んだデータを返す
    f.close()

    # 返す
    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "msh": msh,
            }
        ),
    }