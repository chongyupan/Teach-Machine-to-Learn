%% Omniglot_Sketch_Datasets_Learning
% ������ͼѧϰ���γɲ�ͼʶ�����ݿ⣺
%  CopyRight By PCY, 20180109
clear all;
close all;
clc;
%% �������ݼ����������ã�
way_num=20;          % 5way1shot,5way5shot,5way20shot,20way1shot,20way5shot,20way10shot,20way20shot
shot_num=20;
total_num=way_num*shot_num;
TopN=3;            % TopN�����п��ܵ�ѡ�Single-symbol: 3;  Multiple-symbol: 5;
primitives_num=19;     % �ʻ���Ԫ������: COAD:5   Omniglot:19;
Relation_Distance=0.5;   
symbol_per_sketch=3;   % ÿ����ͼ�а�����symbol��Ŀ��
%% ==========N-way-M-shot sample learning=====================
for echo=1:10    
    %���ػ�Ԫ���ݿ�
    load('../Datasets/Omniglot/Omniglot_object_19_primitives.mat');     
    %ѵ�����ݼ���
    str=['../Datasets/Omniglot/',num2str(way_num),'way',num2str(shot_num),'shot_epho',num2str(echo),'_dataset.mat'];
    load(str);
    for i=1:total_num    % ��i��N-way-M-shot training sample
        Sketch_Data=train_data(1:train_data_length(i),:,i);
        % ��ͼ��Ԫʶ���γ�object_num,object_Name, object_Attribute,object_Relation, object_Attribute_length ѵ����ϵ��
        [Strokes_Num,Attribute,Relation] = Strokes_Recognition( Sketch_Data,Relation_Distance );  % NOTEs: COAD && Omniglot different;
        %%  Sketch_To_Learn�����ص�object���ݼ��У�
        % ��object��object_num
        object_num=object_num+1;
        % ����object��object_Name
        label=num2str(train_label(i));
        for (j=1:length(label))
            object_Name(object_num,j)=label(j);
        end
        % ����object��object_Attribute_length��Attribute
        object_Attribute_length(object_num)=Strokes_Num;
        object_Attribute(object_num,1:object_Attribute_length(object_num))=Attribute;
        % ����object��Relation
        object_Relation(object_num,1:object_Attribute_length(object_num))=Relation;
        fprintf('I have learnt the %dth object: Name:%s;%d strokes\n',object_num, object_Name(object_num,:),object_Attribute_length(object_num));
    end
    str=['object_',num2str(way_num),'way',num2str(shot_num),'shot_epho',num2str(echo)];
    save(['../Datasets/Omniglot/',str],'object_num','object_Name','object_Attribute_length','object_Attribute','object_Relation');
end


