function [path_num,path_weight,path,object_table] = Approximate_Recognition(Strokes_Num,Attribute,Relation,object_num,object_Attribute_length,object_Attribute,object_Relation,primitives_num);
% ����HMM�������·��������
total_vertex_num=Strokes_Num+1;
weight_table=inf(total_vertex_num,total_vertex_num);
object_table=zeros(total_vertex_num,total_vertex_num);
%% Step 1: ����Ȩ�����ӱ�����ν�ĸ��ʱ�
%for i=1:object_num  % ��ÿһ��object���󣨰�����Ԫ������ƥ�䣬����·�������ӦȨֵ������Ч������
for i=(primitives_num+1):object_num        % ��ƥ���Ԫprimitives���ӵ�primitives_num+1��object����ʼ��
    temp_Attribute=object_Attribute(i,1:object_Attribute_length(i));
    temp_Relation=object_Relation(i,1:object_Attribute_length(i));
    temp_length=object_Attribute_length(i);
    %% ����temp_Attribute�������ʻ����н��и���ƥ�䣺
    for j=1:total_vertex_num-temp_length
        %% ����temp_Attribute��temp_Relation��Attribute��Relation����������ͼ��ƥ����ʣ�
        Attribute_cha=temp_Attribute(1:temp_length)-Attribute(j:j+temp_length-1);
        Relation_cha=temp_Relation(1:temp_length)-Relation(j:j+temp_length-1);
        % probability1: for COAD,1 is better than 2;
        probability=(length(find(Attribute_cha==0))+length(find(Relation_cha==0)))/(2*temp_length);
        % probability2:
        %         probability=length(find(Attribute_cha==0))/temp_length;
        % probability3��
        %         probability=Two_Sketch_Compare_rule_1(temp_length,temp_Attribute(1:temp_length),temp_Relation(1:temp_length),temp_length,Attribute(j:j+temp_length-1),Relation(j:j+temp_length-1),primitives_num);
        
        if  (probability>0) && (abs(log(probability))<weight_table(j,j+temp_length))  % ���ʴ���0�������µ�ȨֵС�ڵ�ǰȨֵ�����������ߵ�Ȩ�أ�
            weight_table(j,j+temp_length)=abs(log(probability));   % ����Ȩ��
            object_table(j,j+temp_length)=i;                   % ���¶�Ӧ��object ��
        end
% %         %% ��2��object�ĸ�����ͬʱ����Ҫ����object_table���ӵ�3ά���У���������probability��ȵ�object_num;
%          if (abs(log(probability))== weight_table(j,j+temp_length)) && (object_table(j,j+temp_length)~=i) % ���ʴ���0�������µ�Ȩֵ���ڵ�ǰȨֵ����һ�����е�2��object��
%              tack_index=stack_index+1;
%              stack_table(stack_index,:)=[object_table(j,j+temp_length),i];   % object_table��Ҫ����һ��,��¼��object��
%          end
    end
end
% ����Ȩ�ر���Ӧ��ʵ���б�
% fprintf('The Weight_table is \n');
% weight_table
% object_table
%% Step 2: �����ӽڵ����飺son,son_num
for i=total_vertex_num:-1:1
    temp_son=find(weight_table(:,i)<inf);
    son_num(i)=length(temp_son);
    son(i,1:son_num(i))=temp_son;
end
%% Step 3: ����ÿһ����ӽڵ���Ŀlayer����
end_layer=0;
layer_num(1)=son_num(total_vertex_num);
layer(1,1:layer_num(1))=son(total_vertex_num,1:son_num(total_vertex_num));
i=2;
while end_layer==0
    layer_num(i)=0;
    for j=1:layer_num(i-1)
        temp_layer_num=son_num(layer(i-1,j));
        layer(i,layer_num(i)+1:layer_num(i)+temp_layer_num)=son(layer(i-1,j),1:temp_layer_num);
        layer_num(i)=layer_num(i)+temp_layer_num;
    end
    if layer_num(i)==0
        end_layer=1;
    end
    i=i+1;
end

%% Step 4:���ڸ��ʱ�����������ÿһ���ڵ�node���丸�ڵ�father
index=1;
node(index)=total_vertex_num;
node_num(index)=1;
father(index)=0;
new_index=index+1;
for layer_index=1:length(layer_num)-1
    %% ��չ��layer_num-1�㣬��������ÿһ��չ�����̣�
    count=0;
    for node_index=index:new_index-1
        if(node(node_index)~=1 && son_num(node(node_index))~=0)
            for i=1:son_num(node(node_index))
                % ���常�ڵ㣺���ڵ��ǵڼ���node�������ǵڼ���vertex
                father(new_index+count)=node_index;
                node(new_index+count)=son(node(node_index),i);
                node_num(new_index+count)=new_index+count;
                count=count+1;
            end
        end
    end
    index=new_index;
    new_index=new_index+layer_num(layer_index);
end

%% ���ڹ�����������node-father����Ѱ��ͨ·������ÿһ��ͨ·��Ȩ�غͣ�ͨ·��Ŀpath_num,ͨ·����path,ͨ·Ȩ��path_weight
path_num=0;     % ͨ·��Ŀ
for i=1:length(node)
    if (node(i)==1)
        temp_index=i;
        path_num=path_num+1;
        path_weight(path_num)=0;
        path(path_num,1)=1;
        temp_path=1;
        while father(temp_index)~=0
            temp_path=temp_path+1;
            path(path_num,temp_path)=node(father(temp_index));     % ����ͨ·����
            path_weight(path_num)=path_weight(path_num)+weight_table(path(path_num,temp_path-1),path(path_num,temp_path));
            temp_index=father(temp_index);
        end
    end
end
if path_num==0
    fprintf('No valid path!\n');
    path_weight=[0];
    path=[0];
end
end

