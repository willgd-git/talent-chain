// src/pages/index.tsx
import Navbar from "../components/Navbar";
import ServiceList from "../components/ServiceList";

const Home: React.FC = () => {
  return (
    <div>
      <Navbar />
      <div className="container mx-auto mt-8">
        <h1 className="text-3xl font-bold mb-6">Available Services</h1>
        <ServiceList />
      </div>
    </div>
  );
};

export default Home;
