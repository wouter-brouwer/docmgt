#! /bin/bash
cd /home/wouter/docmgt
rm -r documents/afpinput/tmp/*
rm -r documents/todo/*
rm documents/headers/*
rm -r documents/jobs/*
mv System/hf/afp/*.afp /c/Temp
mv documents/afpinput/processed/*.afp documents/afpinput
