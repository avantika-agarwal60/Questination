import { Navigate, Outlet } from "react-router-dom";
import { useRole } from "../context/RoleContext";

function RequireRole() {
  const { role } = useRole();

  if (!role) {
    return <Navigate to="/login" replace />;
  }

  return <Outlet />;
}

export default RequireRole;