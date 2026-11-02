import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { SplashScreen } from "./components/SplashScreen";
import { AppLayout } from "./components/layout/AppLayout";
import { useAuth } from "./context/AuthContext";
import { AnnouncementsPage } from "./pages/AnnouncementsPage";
import { BookingsPage } from "./pages/BookingsPage";
import { DashboardPage } from "./pages/DashboardPage";
import { DisputesPage } from "./pages/DisputesPage";
import { FederationsPage } from "./pages/FederationsPage";
import { LiveMapPage } from "./pages/LiveMapPage";
import { LoginPage } from "./pages/LoginPage";
import { ServicesPage } from "./pages/ServicesPage";
import { SettingsPage } from "./pages/SettingsPage";
import { SupportPage } from "./pages/SupportPage";
import { UsersPage } from "./pages/UsersPage";
import { WelfarePage } from "./pages/WelfarePage";
import { WorkersPage } from "./pages/WorkersPage";

export function App() {
  const { ready, splashVisible } = useAuth();

  return (
    <>
      {splashVisible ? <SplashScreen fading={ready} /> : null}
      <BrowserRouter basename={import.meta.env.BASE_URL.replace(/\/$/, "") || undefined}>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route element={<AppLayout />}>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/live-map" element={<LiveMapPage />} />
            <Route path="/workers" element={<WorkersPage />} />
            <Route path="/services" element={<ServicesPage />} />
            <Route path="/federations" element={<FederationsPage />} />
            <Route path="/users" element={<UsersPage />} />
            <Route path="/bookings" element={<BookingsPage />} />
            <Route path="/disputes" element={<DisputesPage />} />
            <Route path="/welfare" element={<WelfarePage />} />
            <Route path="/support" element={<SupportPage />} />
            <Route path="/announcements" element={<AnnouncementsPage />} />
            <Route path="/settings" element={<SettingsPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </>
  );
}
