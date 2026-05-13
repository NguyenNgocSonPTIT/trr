#include<bits/stdc++.h>
using namespace std;
 
int a[100][100]={0};
 int main(){
     int t; cin>>t;
     int n,m;
     cin>>n>>m;
     int u,v;
     for (int i=1;i<=m;i++){
          cin>>u>>v;

          a[u][v]=1;
          a[v][u]=1;
     }
     if(t==1){
        for (int i=1;i<=n;i++)
        {
            int deg=0;
            for (int j=1;j<=n;j++){
                deg+=a[i][j];
            }
            cout<<deg<<" ";
        }
     }
     else{
        cout<<n<<endl;
        for (int i=1;i<=n;i++){
            for (int j=1;j<=n;j++){
                cout<<a[i][j]<<" ";
            }
            cout<<endl;
        }
     }
 }