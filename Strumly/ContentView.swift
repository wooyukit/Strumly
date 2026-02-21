import SwiftUI
import StrumlyCore
import StrumlyTuner

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Songs", systemImage: "music.note.list") {
                SongListView(api: StrumlyAPI(baseURL: URL(string: "https://strumly-api.web.app/api")!))
            }

            Tab("Chords", systemImage: "guitars") {
                ChordBrowserView()
            }

            Tab("Tuner", systemImage: "tuningfork") {
                TunerView()
            }
        }
    }
}

#Preview {
    ContentView()
}
