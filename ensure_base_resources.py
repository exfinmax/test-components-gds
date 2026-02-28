import glob, os
for path in glob.glob(r'd:/Hopes_and_Dream/Godotprojects/test-components-gds/ComponentLibrary/Packs/**/Demo/*.tscn', recursive=True):
    lines=open(path,'r',encoding='utf-8').read().splitlines()
    if any('component_base.gd' in ln for ln in lines):
        continue
    new=[]
    inserted=False
    for ln in lines:
        new.append(ln)
        if not inserted and ln.strip().startswith('[ext_resource'):
            new.append('[ext_resource type="Script" path="res://ComponentLibrary/Dependencies/component_base.gd" id="99"]')
            new.append('[ext_resource type="Script" path="res://ComponentLibrary/Dependencies/character_component_base.gd" id="100"]')
            inserted=True
    open(path,'w',encoding='utf-8').write("\n".join(new))
    print('added base deps to', path)
