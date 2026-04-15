
#if 0
/** 
 * struct ListNode {
 *  int val;
 *  struct ListNode *next;
 * }
 */

 struct Merge_ListNode(const ListNode* Node1, const ListNode* Node2){
    if(Node1 == NULL){
        return Node2;
    }
    if(Node2 == NULL){
        return Node1;
    }
    struct ListNode* temp = malloc(sizeof(struct ListNode));
    temp->next = NULL;
    if(Node1.val <= Node2.val){
        temp = Node1;
        temp->next = Merge_ListNode(Node1->next, Node2);
    }
    else{
        temp = Node2;
        temp->next = Merge_ListNode(Node1, Node2->next);
    }
    return temp;
 }


 /
 #endif 

 struct ListNode{
    int val;
    struct ListNode* next;
 }

struct ListNode* merge(const struct ListNode* head1,const struct ListNode* head2){
    if(head1 == NULL){
        return head2;
    }
    if(head2 == NULL){
        return head1;
    }
    struct ListNode *temp = malloc(sizeof(struct ListNode));//这里可以直接写空指针，不然会有内存泄露
    
    struct ListNode *temp = NULL;

    temp->next = NULL;
    if(head1->val <= head2->val){
        temp = head1;
        temp->next = merge(head1->next, head2);
    }
    else{
        temp = head2;
        temp->next = merge(head1, head2->next);
    }
    return temp;
}
