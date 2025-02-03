import SwiftUI

struct AlertTemplateView: View {
    let element: AlertDetails
    let onDelete: (AlertDetails) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            /*Text(element.title)
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineSpacing(-20)
                .foregroundColor(Color(.black))
            */
            Text(element.errorDescription)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(Color(.black))
        }
        .padding()
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(element.intentAlert ? .red : .green).opacity(0.3))
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                onDelete(element)
            }
        }
    }
}

struct AlertTemplateView_Previews: PreviewProvider {
    static var previews: some View {
        AlertTemplateView(
            element: AlertDetails(title: "Nero", errorDescription: "Default", intentAlert: true),
            onDelete: { AlertDetails in }
        )
    }
}
