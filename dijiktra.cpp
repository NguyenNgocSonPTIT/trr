#include <iostream>
#include <vector>
#include <queue>
#include <fstream>
#include <algorithm>

using namespace std;

const int INF = 10000; // Vô cùng theo quy ước đề bài

int main() {
    // 1. CHUẨN BỊ DỮ LIỆU
    ifstream cin("DN.INP");
    ofstream cout("DN.OUT");

    int n, s, t;
    if (!(cin >> n >> s >> t)) return 0;

    // Lưu đồ thị bằng danh sách kề để duyệt cho nhanh
    vector<pair<int, int>> adj[101];
    for (int i = 1; i <= n; i++) {
        for (int j = 1; j <= n; j++) {
            int w; cin >> w;
            if (w > 0 && w < INF) adj[i].push_back({j, w});
        }
    }

    // 2. KHỞI TẠO THUẬT TOÁN
    vector<int> d(n + 1, INF);     // d[i]: quãng đường ngắn nhất từ s đến i
    vector<int> truoc(n + 1, 0);   // truoc[i]: đỉnh đứng ngay trước i trong lộ trình
    d[s] = 0;                      // Xuất phát từ s nên d[s] = 0

    // Priority Queue: Luôn đưa đỉnh có d[u] nhỏ nhất lên đầu
    priority_queue<pair<int, int>, vector<pair<int, int>>, greater<pair<int, int>>> pq;
    pq.push({0, s}); 

    // 3. VÒNG LẶP CHÍNH (Cốt lõi của Dijkstra)
    while (!pq.empty()) {
        int u = pq.top().second; // Lấy đỉnh "tiềm năng" nhất ra
        int dist = pq.top().first;
        pq.pop();

        if (dist > d[u]) continue; // Bỏ qua nếu dữ liệu này đã cũ
        if (u == t) break;         // Đã tới đích, dừng sớm cho nhanh

        // Xét các hàng xóm v của u
        for (auto edge : adj[u]) {
            int v = edge.first;
            int weight = edge.second;

            // Kỹ thuật RELAX (Nới lỏng): Nếu đi qua u ngắn hơn đường cũ
            if (d[v] > d[u] + weight) {
                d[v] = d[u] + weight;
                truoc[v] = u;      // Đánh dấu: "Đến v thì phải qua u mới gần"
                pq.push({d[v], v});
            }
        }
    }

    // 4. XUẤT KẾT QUẢ
    if (d[t] >= INF) {
        cout << 0; // Không có đường đi
    } else {
        cout << d[t] << endl;
        
        // Truy vết ngược từ t về s
        vector<int> path;
        for (int v = t; v != 0; v = truoc[v]) path.push_back(v);
        reverse(path.begin(), path.end());

        for (int i = 0; i < path.size(); i++) 
            cout << path[i] << (i == path.size() - 1 ? "" : " ");
    }
    return 0;
}