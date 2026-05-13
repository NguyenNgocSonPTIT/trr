//ma trận liên thuộc
#include<bits/stdc++.h>
using namespace std;
int n;
int a[100][100];
int im[101][1000];
int main(){
    int t; cin>>t;
    cin>>n;
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
        int m=0;            //tạo biến làm cạnh 
        for (int i=1;i<=n-1;i++){
            for (int j=i+1;j<=n;j++){
                if(a[i][j]==1){
                    m++;    //nếu 2 đinht kề thì cong 1 cạnh 
                    im[i][m]=1;  im[j][m]=1;// Cho canh m lien thuoc voi dinh u va v trong ma tran "im[][]"
                }
            }
        }
        cout<<n<<" "<<m<<endl;
        for (int i=1;i<=n;i++){
            for (int j=1;j<=m;j++){
                cout<<im[i][j]<<" ";
            }
            cout<<endl;
        }
    }
}