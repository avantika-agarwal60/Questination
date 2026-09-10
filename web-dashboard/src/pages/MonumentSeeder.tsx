import { useState } from "react";
import { Landmark } from "lucide-react";
import PageHeader from "../components/PageHeader";

function MonumentSeeder() {
  const [name, setName] = useState("");
  const [city, setCity] = useState("");
  const [description, setDescription] = useState("");
  const [savedMonuments, setSavedMonuments] = useState<string[]>([]);

  function handleAdd() {
    if (name && city) {
      setSavedMonuments([...savedMonuments, `${name} (${city})`]);
      setName("");
      setCity("");
      setDescription("");
    }
  }

  return (
    <div>
      <PageHeader title="Add Monument" subtitle="Seed a new heritage site into the platform." />
      <div className="w-full max-w-md">
        <div className="bg-white p-8 rounded-2xl shadow-lg shadow-emerald-900/5 border border-amber-100 mb-6">
          <div className="flex items-center gap-2 mb-4 text-emerald-700">
            <Landmark size={22} />
            <span className="font-semibold">Monument Details</span>
          </div>

          <label className="block text-sm font-medium mb-1 text-gray-700">Monument Name</label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="w-full border border-gray-200 rounded-lg px-4 py-3 mb-3 focus:outline-none focus:ring-2 focus:ring-emerald-400 transition"
          />

          <label className="block text-sm font-medium mb-1 text-gray-700">City</label>
          <input
            type="text"
            value={city}
            onChange={(e) => setCity(e.target.value)}
            className="w-full border border-gray-200 rounded-lg px-4 py-3 mb-3 focus:outline-none focus:ring-2 focus:ring-emerald-400 transition"
          />

          <label className="block text-sm font-medium mb-1 text-gray-700">Description</label>
          <textarea
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="w-full border border-gray-200 rounded-lg px-4 py-3 mb-4 focus:outline-none focus:ring-2 focus:ring-emerald-400 transition"
            rows={3}
          />

          <button
            onClick={handleAdd}
            className="w-full bg-emerald-700 text-white py-3 rounded-lg font-medium hover:bg-emerald-800 transition shadow-md shadow-emerald-900/20"
          >
            Add Monument
          </button>
        </div>

        {savedMonuments.length > 0 && (
          <div>
            <h2 className="font-semibold mb-2 text-gray-700">Added Monuments:</h2>
            {savedMonuments.map((m, i) => (
              <p key={i} className="bg-white p-3 rounded-xl shadow border border-amber-100 mb-2 text-sm text-gray-700">
                {m}
              </p>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default MonumentSeeder;