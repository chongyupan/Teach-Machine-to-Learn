%% Omniglot_Sketch_Datasets_Learning
%  CopyRight By PCY, 20180109
clear all;
close all;
clc;
%% �������ݼ����������ã�
way_num=20;           % 5way1shot,5way5shot,5way20shot,20way1shot,20way5shot,20way10shot,20way20shot
shot_num=20;
total_num=way_num*shot_num;
TopN=3;            % TopN�����п��ܵ�ѡ�Single-symbol: 3;  Multiple-symbol: 5;
primitives_num=19;    
Relation_Distance=0.5;   
symbol_per_sketch=3;   % ÿ����ͼ�а�����symbol��Ŀ��

%% ===================Multiple symbol recognition test========================
% % % % ���ز������ݼ������Ӧ��object���ݿ⣺
for echo=1:10              %1:10
    str=['../Datasets/Omniglot/',num2str(way_num),'way',num2str(shot_num),'shot_epho',num2str(echo),'_dataset.mat'];
     load(str);
    str=['../Datasets/Omniglot/object_',num2str(way_num),'way',num2str(shot_num),'shot_epho',num2str(echo),'.mat'];
     load(str);
    Top1_True_Count=0;
    TopN_True_Count=0;
    total_query_num=size(multiple_label,1);          % 1100
    stack_index=0;
    %% FineTune: ����object_Attribute��object_Relation���ҳ�������ͬAttribute��Relation��object������object_stack_short_table:
    for i=(primitives_num+1):object_num
        for j=i:object_num
            object_Attribute_i=object_Attribute(i,1:object_Attribute_length(i));
            object_Attribute_j=object_Attribute(j,1:object_Attribute_length(j));
            object_Relation_i=object_Relation(i,1:object_Attribute_length(i));
            object_Relation_j=object_Relation(j,1:object_Attribute_length(j));
            if (j~=i) && object_Attribute_length(i)==object_Attribute_length(j) && sum(abs(object_Attribute_i-object_Attribute_j))==0 && sum(abs(object_Relation_i-object_Relation_j))==0 && strcmp(object_Name(i,:),object_Name(j,:))==0
                stack_index=stack_index+1;
                stack_table(stack_index,:)=[i,j];
                object_stack_table(stack_index,:)=[str2num(object_Name(i,:)),str2num(object_Name(j,:))];
            end
        end
    end
    % ���object_stack_table����ȥ�أ�
    if stack_index>0
        stack_short_index=1;
        object_stack_short_table(1,:)=object_stack_table(1,:);
        for i=2:stack_index
            repeat=0;
            query=object_stack_table(i,:);
            for j=1:stack_short_index
                if sum(query==object_stack_short_table(j,:))==2
                    repeat=1;
                end
            end
            if repeat==0
                stack_short_index=stack_short_index+1;
                object_stack_short_table(stack_short_index,:)=query;
            end
        end
    end
    %% ���ÿһ��sample����ʶ��ƥ���ƶϣ�
    for sample_no=(1:1100)+00             % 1:1100��11��: (1:100)+500
        fprintf('Processing %dth/10 echo, %dth/1100 sample;\n',echo,sample_no);
        Sketch_Data=multiple_test_data(1:multiple_test_data_length(sample_no),:,sample_no);
        %                         figure;
        %                         plot(Sketch_Data(:,1),Sketch_Data(:,2),'*');
        %                         hold on;
        %                         plot(Sketch_Data(1,1),Sketch_Data(1,2),'r*');
        label=multiple_label(sample_no,:);
        fprintf('The GroundTruth label is: %s\n',num2str(label));
        % ��Sketch_Data���бʻ���Ԫʶ��
        [Strokes_Num,Attribute,Relation] = Strokes_Recognition( Sketch_Data,Relation_Distance );  % NOTEs: COAD && Omniglot different;
        %         Attribute
        % ��֪ʶ���м���������ÿһ��ͨ·����ͨ·Ȩ�غͣ�չ��Ȩ�غ���С��Top N;
        [ path_num,path_weight,path,object_table] = Approximate_Recognition(Strokes_Num,Attribute,Relation,object_num,object_Attribute_length,object_Attribute,object_Relation,primitives_num);
        %% ��TOP N·������ʵ����ʾobjects presentation:
        if (path_num==0)  % ���󱨾���û���ҵ�ƥ��·��
            fprintf('No Resembale Sketch��\nTo Learn OR Redraw, Please��\n');
        else
            [sorted_path_weight,sort_order]=sort(path_weight);
            TopN_have_added=0;
            for i=1:min(TopN,path_num)             % NOTE: �Է�·������path_numС��TOP_N
                path_index=sort_order(i);
                %                 fprintf('\nThe %dth Likely Recognition Result is: ',i);
                % չʾ��path_index��·������path_index�е�object;
                label_temp_length=length(find(path(path_index,:)>0))-1;
                label_temp=zeros(1,label_temp_length);
                for j=1:label_temp_length
                    temp_object_num=object_table(path(path_index,j),path(path_index,j+1));
                    %                     fprintf('%s;',object_Name(temp_object_num,:));
                    label_temp(j)=str2num(object_Name(temp_object_num,:));
                end
                % ����label_tempͳ����ȷʶ����������object_stack_short_table���ر��е��ص����
                if stack_index>0   % Finetune: ���ڶ��object����1���ߵ������ƥ��label_temp���й����object;
                    symbol_true=zeros(1,symbol_per_sketch);
                    if label_temp_length==symbol_per_sketch
                        for symbol_index=1:symbol_per_sketch
                            available_object_num=object_stack_short_table(find(object_stack_short_table(:,1)==label_temp(symbol_index)),2);
                            if label(symbol_index)==label_temp(symbol_index) || sum(label(symbol_index)==available_object_num)>0
                                symbol_true(symbol_index)=1;
                            end
                        end
                    end
                    
                    if sum(symbol_true)==symbol_per_sketch
                        if i==1
                            Top1_True_Count=Top1_True_Count+1;
                            TopN_True_Count=TopN_True_Count+1;
                            TopN_have_added=1;
                            fprintf('Top1 True! The %dth Likely Recognition Result is: %s\n',i,num2str(label_temp));
                        else
                            if TopN_have_added==0
                                TopN_True_Count=TopN_True_Count+1;
                                TopN_have_added=1;
                                fprintf('TopN True! The %dth Likely Recognition Result is: %s\n',i,num2str(label_temp));
                            end
                        end
                    end
                else    % No Finetune,ֱ��ƥ��label_temp
                    fprintf('The %dth Likely Recognition Result is: %s\n',i,num2str(label_temp));
                    if (label_temp_length==symbol_per_sketch) && (sum(label==label_temp)==symbol_per_sketch)
                        if i==1
                            Top1_True_Count=Top1_True_Count+1;
                            TopN_True_Count=TopN_True_Count+1;
                            TopN_have_added=1;
                        else
                            if TopN_have_added==0
                                TopN_True_Count=TopN_True_Count+1;
                                TopN_have_added=1;
                            end
                        end
                    end
                end
            end
        end
    end
    Top1_recall_rate(echo)=Top1_True_Count/1100;
    TopN_recall_rate(echo)=TopN_True_Count/1100;
    fprintf('Top1 Recall Rate is %f\n',Top1_recall_rate(echo));
    fprintf('TopN Recall Rate is %f\n',TopN_recall_rate(echo));
end
str_save=['../Datasets/Omniglot/Acc_for_Multiple_symbol_recognition_',num2str(way_num),'way',num2str(shot_num),'shot.mat'];
save(str_save,'Top1_recall_rate','TopN_recall_rate') ;
Top1_recall_rate
