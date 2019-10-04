function [path_num,path_weight,path,object_table] = Approximate_Recognition(Strokes_Num,Attribute,Relation,object_num,object_Attribute_length,object_Attribute,object_Relation,primitives_num);
% 基于HMM进行最短路径搜索：
total_vertex_num=Strokes_Num+1;
weight_table=inf(total_vertex_num,total_vertex_num);
object_table=zeros(total_vertex_num,total_vertex_num);
%% Step 1: 构造权重连接表，即所谓的概率表：
%for i=1:object_num  % 对每一个object对象（包含基元）进行匹配，生成路径及其对应权值：试验效果更好
for i=(primitives_num+1):object_num        % 不匹配基元primitives，从第primitives_num+1个object对象开始；
    temp_Attribute=object_Attribute(i,1:object_Attribute_length(i));
    temp_Relation=object_Relation(i,1:object_Attribute_length(i));
    temp_length=object_Attribute_length(i);
    %% 基于temp_Attribute对整个笔画序列进行概率匹配：
    for j=1:total_vertex_num-temp_length
        %% 基于temp_Attribute，temp_Relation和Attribute，Relation计算两个草图的匹配概率：
        Attribute_cha=temp_Attribute(1:temp_length)-Attribute(j:j+temp_length-1);
        Relation_cha=temp_Relation(1:temp_length)-Relation(j:j+temp_length-1);
        % probability1: for COAD,1 is better than 2;
        probability=(length(find(Attribute_cha==0))+length(find(Relation_cha==0)))/(2*temp_length);
        % probability2:
        %         probability=length(find(Attribute_cha==0))/temp_length;
        % probability3：
        %         probability=Two_Sketch_Compare_rule_1(temp_length,temp_Attribute(1:temp_length),temp_Relation(1:temp_length),temp_length,Attribute(j:j+temp_length-1),Relation(j:j+temp_length-1),primitives_num);
        
        if  (probability>0) && (abs(log(probability))<weight_table(j,j+temp_length))  % 概率大于0，并且新的权值小于当前权值，则更替该条边的权重：
            weight_table(j,j+temp_length)=abs(log(probability));   % 更新权重
            object_table(j,j+temp_length)=i;                   % 更新对应的object 号
        end
% %         %% 当2个object的概率相同时，需要考虑object_table增加第3维序列，表征所有probability相等的object_num;
%          if (abs(log(probability))== weight_table(j,j+temp_length)) && (object_table(j,j+temp_length)~=i) % 概率大于0，并且新的权值等于当前权值，则一条边有第2种object：
%              tack_index=stack_index+1;
%              stack_table(stack_index,:)=[object_table(j,j+temp_length),i];   % object_table需要增加一条,记录该object号
%          end
    end
end
% 概率权重表及对应的实体列表：
% fprintf('The Weight_table is \n');
% weight_table
% object_table
%% Step 2: 构建子节点数组：son,son_num
for i=total_vertex_num:-1:1
    temp_son=find(weight_table(:,i)<inf);
    son_num(i)=length(temp_son);
    son(i,1:son_num(i))=temp_son;
end
%% Step 3: 构造每一层的子节点数目layer数组
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

%% Step 4:基于概率表构建搜索树：每一个节点node及其父节点father
index=1;
node(index)=total_vertex_num;
node_num(index)=1;
father(index)=0;
new_index=index+1;
for layer_index=1:length(layer_num)-1
    %% 共展开layer_num-1层，这里描述每一层展开过程：
    count=0;
    for node_index=index:new_index-1
        if(node(node_index)~=1 && son_num(node(node_index))~=0)
            for i=1:son_num(node(node_index))
                % 定义父节点：父节点是第几个node，而不是第几个vertex
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

%% 基于构建的搜索树node-father矩阵寻找通路并计算每一条通路的权重和：通路数目path_num,通路矩阵path,通路权重path_weight
path_num=0;     % 通路数目
for i=1:length(node)
    if (node(i)==1)
        temp_index=i;
        path_num=path_num+1;
        path_weight(path_num)=0;
        path(path_num,1)=1;
        temp_path=1;
        while father(temp_index)~=0
            temp_path=temp_path+1;
            path(path_num,temp_path)=node(father(temp_index));     % 构造通路矩阵
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

