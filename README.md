# CutAudioProject
***切割从网上爬取的MP3数据，用于语音识别模型训练***

### 1.用法：
- perl CutWavByVadnn.pl input threadnum

### 2.输入：
- a.爬取结果的结果文件（res）；
- b.并发线程数；

### 3.输出：
- a.格式为json的input文件，详细格式如下：
```
{
  "filename" : "",     #wavname
  "url": "",           #url
  "info": "",          #text
  "time": "",          #timestampt
  "subwav":[]          
}

```

