#include<bits/stdc++.h>
using namespace std;
 int a[100][100];
 int vs[100]={0};
 int n;
  void dfs(int u){
    vs[u]=1;
    for (int v=1;v<=n;v++){
        if(a[u][v]==1 && vs[v]==0){
            cout<<v<<"("<<u<<")"<<" ";
            dfs(v);
        }
    }

  }
int main(){
    cin>>n;
    for (int i=1;i<=n;i++){
        for(int j=1;j<=n;j++){
            cin>>a[i][j];
        }
    }
    int start ;
    cin>>start;
    dfs(start);
}