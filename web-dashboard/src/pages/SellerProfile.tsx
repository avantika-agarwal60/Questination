import { useState } from "react";
import { Store, CheckCircle2, IdCard } from "lucide-react";
import PageHeader from "../components/PageHeader";

function SellerProfile() {
  const [shopName, setShopName] = useState("");
  const [category, setCategory] = useState("");
  const [phone, setPhone] = useState("");
  const [docId, setDocId] = useState("");
  const [saved, setSaved] = useState(false);

  function handleSave() {
    if (shopName && category && phone && docId) {
      setSaved(true);
      // Later: this is where we'll call the real backend, e.g.
      // { shopName, category, phone, docId, verificationStatus: "pending" }
      console.log({ shopName, category, phone, docId });
    }
  }

  return (
    <div>
      <PageHeader title="Seller Profile" subtitle="Set up your shop so tourists can find and support you." />
      <div className="bg-white p-8 rounded-2xl shadow-lg shadow-emerald-900/5 w-full max-w-md border border-amber-100">
        <div className="flex items-center gap-2 mb-4 text-emerald-700">
          <Store size={22} />
          <span className="font-semibold">Shop Details</span>
        </div>

        <label className="block text-sm font-medium mb-1 text-gray-700">Shop Name</label>
        <input
          type="text"
          value={shopName}
          onChange={(e) => setShopName(e.target.value)}
          className="w-full border border-gray-200 rounded-lg px-4 py-3 mb-3 focus:outline-none focus:ring-2 focus:ring-emerald-400 transition"
        />

        <label className="block text-sm font-medium mb-1 text-gray-700">Category</label>
        <input
          type="text"
          placeholder="e.g. Handicrafts"
          value={category}
          onChange={(e) => setCategory(e.target.value)}
          className="w-full border border-gray-200 rounded-lg px-4 py-3 mb-3 focus:outline-none focus:ring-2 focus:ring-emerald-400 transition"
        />

        <label className="block text-sm font-medium mb-1 text-gray-700">Phone Number</label>
        <input
          type="text"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          className="w-full border border-gray-200 rounded-lg px-4 py-3 mb-3 focus:outline-none focus:ring-2 focus:ring-emerald-400 transition"
        />

        <div className="flex items-center gap-2 mb-1 text-gray-700">
          <IdCard size={16} />
          <label className="text-sm font-medium">
            Government Registration ID (Udyam / PEHCHAN / ODOP)
          </label>
        </div>
        <input
          type="text"
          placeholder="e.g. UDYAM-2938"
          value={docId}
          onChange={(e) => setDocId(e.target.value)}
          className="w-full border border-gray-200 rounded-lg px-4 py-3 mb-4 focus:outline-none focus:ring-2 focus:ring-emerald-400 transition"
        />

        <button
          onClick={handleSave}
          className="w-full bg-emerald-700 text-white py-3 rounded-lg font-medium hover:bg-emerald-800 transition shadow-md shadow-emerald-900/20"
        >
          Save Profile
        </button>

        {saved && (
          <div className="mt-5 flex items-center gap-2 bg-green-50 text-green-700 px-4 py-3 rounded-lg">
            <CheckCircle2 size={20} />
            <span className="font-medium">
              Profile saved! Your application is now pending admin approval.
            </span>
          </div>
        )}
      </div>
    </div>
  );
}

export default SellerProfile;