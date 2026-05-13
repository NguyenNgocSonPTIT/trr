#include<bits/stdc++.h>
using namespace std;

int a[100][100];
vector<int>vt;
int main(){
    freopen("DT.INP", "r", stdin);
    freopen("DT.OUT", "w", stdout);
    int t; cin>>t;
    int n; cin>>n;
    for (int i=1;i<=n;i++){
        for (int j=1;j<=n;j++){
            cin>>a[i][j];
        }
    }
    if(t==1){
        for (int i=1;i<=n;i++){
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
            int count=0;
            for(int j=1;j<=n;j++){
                if(a[i][j]==1){
                   count+=1;
                }
            }cout<<count<<" ";
            for(int j=1;j<=n;j++){
                if(a[i][j]==1)cout<<j<<" ";
            }
            cout<<endl;
        }
        
    }
}