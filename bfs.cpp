#include<bits/stdc++.h>
using namespace std;
int a[100][100],vs[100];
int n, start;
queue<int>q;
 
void bfs(int st){
    vs[st]=1;
    q.push(st);
    while(!q.empty()){
        int u=q.front();
        for(int v=1;v<=n;v++){
            if(a[u][v]==1 && vs[v]==0){
               vs[v]=1;
               cout<<v<<"("<<u<<")";
               q.push(v);
            }
        }
        q.pop();
    }
}
int main(){
    cin>>n;
    for (int i=1;i<=n;i++){
        for (int j=1;j<=n;j++){
            cin>>a[i][j];
        }
    }
    cin>>start;
    bfs(start);
}