%% ==========M-way-N-shot sample learning=====================
% 单个草图学习，形成草图识别数据库：
%  CopyRight By PCY, 20180109
clear all;
close all;
clc;
%% 加载数据集及参数设置：
way_num=5;                % 5way1shot,5way5shot,20way1shot,20way5shot
shot_num=1;
total_num=way_num*shot_num;
Relation_Distance=1.0;      

for echo=1:10
    %加载基元数据库
    load('../Datasets/COAD/COAD_object_5_primitives.mat');   
    %训练数据集：
    str=['../Datasets/COAD/',num2str(way_num),'way',num2str(shot_num),'shot_epho',num2str(echo),'_dataset.mat'];
    load(str);
    for i=1:total_num    % 第i个N-way-M-shot training sample
        Sketch_Data=train_data(1:train_data_length(i),:,i);
        % 草图基元识别：形成object_num,object_Name, object_Attribute,object_Relation, object_Attribute_length 训练关系表：
        [Strokes_Num,Attribute,Relation] = Strokes_Recognition( Sketch_Data,Relation_Distance );  % NOTEs: COAD && Omniglot different;
        %%  Sketch_To_Learn：加载到object数据集中；
        % 新object的object_num
        object_num=object_num+1;
        % 存新object的object_Name
        label=num2str(train_label(i));
        for (j=1:length(label))
            object_Name(object_num,j)=label(j);
        end
        % 存新object的object_Attribute_length和Attribute
        object_Attribute_length(object_num)=Strokes_Num;
        object_Attribute(object_num,1:object_Attribute_length(object_num))=Attribute;
        % 存新object的Relation
        object_Relation(object_num,1:object_Attribute_length(object_num))=Relation;
        fprintf('I have learnt the %dth object: Name:%s;%d strokes\n',object_num, object_Name(object_num,:),object_Attribute_length(object_num));
    end
    str=['object_',num2str(way_num),'way',num2str(shot_num),'shot_epho',num2str(echo)];
    save(['../Datasets/COAD/',str],'object_num','object_Name','object_Attribute_length','object_Attribute','object_Relation');
end



