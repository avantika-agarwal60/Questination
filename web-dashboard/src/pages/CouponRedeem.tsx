import { useState } from "react";
import { CheckCircle2, XCircle, TicketPercent } from "lucide-react";
import PageHeader from "../components/PageHeader";

const validCoupons = ["RIYA-4829", "AMIT-1023", "PRIYA-5567"];

function CouponRedeem() {
  const [code, setCode] = useState("");
  const [result, setResult] = useState<null | "success" | "fail">(null);

  function handleConfirm() {
    setResult(validCoupons.includes(code) ? "success" : "fail");
  }

  return (
    <div>
      <PageHeader
        title="Verify Customer Coupon"
        subtitle="Enter the code your customer showed you to apply their discount."
      />

      <div className="bg-white p-8 rounded-2xl shadow-lg shadow-emerald-900/5 w-full max-w-md border border-amber-100">
        <div className="flex items-center gap-2 mb-4 text-emerald-700">
          <TicketPercent size={22} />
          <span className="font-semibold">Coupon Code</span>
        </div>

        <input
          type="text"
          placeholder="e.g. RIYA-4829"
          value={code}
          onChange={(e) => setCode(e.target.value)}
          className="w-full border border-gray-200 rounded-lg px-4 py-3 mb-4 focus:outline-none focus:ring-2 focus:ring-emerald-400 transition"
        />

        <button
          onClick={handleConfirm}
          className="w-full bg-emerald-700 text-white py-3 rounded-lg font-medium hover:bg-emerald-800 transition shadow-md shadow-emerald-900/20"
        >
          Confirm
        </button>

        {result === "success" && (
          <div className="mt-5 flex items-center gap-2 bg-green-50 text-green-700 px-4 py-3 rounded-lg">
            <CheckCircle2 size={20} />
            <span className="font-medium">Coupon redeemed successfully!</span>
          </div>
        )}
        {result === "fail" && (
          <div className="mt-5 flex items-center gap-2 bg-red-50 text-red-700 px-4 py-3 rounded-lg">
            <XCircle size={20} />
            <span className="font-medium">Invalid or already used coupon.</span>
          </div>
        )}
      </div>
    </div>
  );
}

export default CouponRedeem;