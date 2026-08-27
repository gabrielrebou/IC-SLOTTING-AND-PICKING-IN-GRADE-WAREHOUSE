Two sets of benchmark instances have been used for the computational experiments of the article 
"The Storage Location Assignment and Picker Routing Problem: A Generic Branch-Cut-and-Price Algorithm"


The first set of instances comes from the paper
"Integrating storage location and order picking problems in warehouse planning"
authored by Allyson Silva, Leandro C. Coelho, Maryzam Darvish and Jacques Renaud.
https://doi.org/10.1016/j.tre.2020.102003
Their instances are available on the following website: https://www.leandro-coelho.com/slot-assignment-and-order-picking/


The second set of instances comes from the paper
"Storage assignment for newly arrived items in forward picking areas with limited open locations"
authored by Xiaolong Guo, Ran Chen, Shaofu Du and Yugang Yu.
https://doi.org/10.1016/j.tre.2021.102359
The set of small instances is made available on this repository, with the kind permission of the authors. 


The instance files use a similar template than (Silva et al. 2020)
The first line contains the number of aisles and the number of bays per aisle
The second line contains the paramters wa, wb and wc (see Guo et al. 2021)
The third line contains the number of SKUs
The fourth line contains the number of orders |O|
The fifth line contains the length of each order 
The |O| following lines contain, for each order, the list of SKUs to pick
The following lines, until the end, contain the fixed assignments (SKU, location)