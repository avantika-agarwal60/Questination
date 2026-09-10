import { useState } from "react";
import { ShieldCheck, Check, X } from "lucide-react";
import PageHeader from "../components/PageHeader";

interface Application {
  id: string;
  name: string;
  role: "seller";
  docId: string;
  verificationStatus: "pending" | "approved" | "rejected";
}

const initialApplications: Application[] = [
  { id: "1", name: "Ramesh Handicrafts", role: "seller", docId: "UDYAM-2938", verificationStatus: "pending" },
  { id: "2", name: "Local Pottery Co.", role: "seller", docId: "ODOP-4471", verificationStatus: "pending" },
];

function ApprovalQueue() {
  const [applications, setApplications] = useState<Application[]>(initialApplications);

  function handleApprove(id: string) {
    setApplications(applications.filter((app) => app.id !== id));
  }

  function handleReject(id: string) {
    setApplications(applications.filter((app) => app.id !== id));
  }

  return (
    <div>
      <PageHeader title="Pending Approvals" subtitle="Verify seller documents before granting access." />
      <div className="w-full max-w-lg flex flex-col gap-3">
        {applications.length === 0 && (
          <p className="text-gray-500">No pending applications.</p>
        )}
        {applications.map((app) => (
          <div
            key={app.id}
            className="bg-white p-4 rounded-2xl shadow-lg shadow-emerald-900/5 border border-amber-100 flex justify-between items-center"
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-full bg-emerald-50 text-emerald-700 flex items-center justify-center">
                <ShieldCheck size={18} />
              </div>
              <div>
                <p className="font-semibold text-gray-800">{app.name}</p>
                <p className="text-sm text-gray-500 capitalize">{app.role} • Doc ID: {app.docId}</p>
              </div>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => handleApprove(app.id)}
                className="flex items-center gap-1 bg-emerald-700 text-white px-3 py-2 rounded-lg hover:bg-emerald-800 transition text-sm"
              >
                <Check size={16} /> Approve
              </button>
              <button
                onClick={() => handleReject(app.id)}
                className="flex items-center gap-1 bg-red-50 text-red-600 px-3 py-2 rounded-lg hover:bg-red-100 transition text-sm"
              >
                <X size={16} /> Reject
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

export default ApprovalQueue;