### 1 markdown把图片编码进文本内保存的方式 - 通过python


```python
import base64
# 计算图片base64的转码
path = r'C:\Users\opink\Desktop\testjpg1.png'

f = open(path,'rb')
ls_f = base64.b64encode(f.read())
f.close()
print(ls_f)

f"""  后在markdown里扔到最后面
![avatar][base64str1]

[base64str1]:data:image/png;base64,{ls_f}

"""

```



![avatar][base64str1]

[base64str1]:data:image/png;base64,/9j/4AAQSkZJRgABAQEAYABgAAD/......UUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAFFFFABRRRQAUUUUAf/2Q==