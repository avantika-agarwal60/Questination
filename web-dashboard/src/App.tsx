import { BrowserRouter, Routes, Route } from "react-router-dom";
import { RoleProvider } from "./context/RoleContext";
import RequireRole from "./components/RequireRole";
import Layout from "./components/Layout";
import RoleSelect from "./pages/RoleSelect";
import CouponRedeem from "./pages/CouponRedeem";
import SellerProfile from "./pages/SellerProfile";
import RatingsView from "./pages/RatingsView";
import ApprovalQueue from "./pages/ApprovalQueue";
import MonumentSeeder from "./pages/MonumentSeeder";

function App() {
  return (
    <RoleProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<RoleSelect />} />
          <Route element={<RequireRole />}>
            <Route element={<Layout />}>
              <Route path="/" element={<CouponRedeem />} />
              <Route path="/profile" element={<SellerProfile />} />
              <Route path="/ratings" element={<RatingsView />} />
              <Route path="/admin" element={<ApprovalQueue />} />
              <Route path="/monuments" element={<MonumentSeeder />} />
            </Route>
          </Route>
        </Routes>
      </BrowserRouter>
    </RoleProvider>
  );
}

export default App;