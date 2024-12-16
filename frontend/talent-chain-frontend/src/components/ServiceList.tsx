// src/components/ServiceList.tsx
import ServiceCard from "./ServiceCard";
import { IService } from "../types/index";

const dummyServices: IService[] = [
  {
    id: "1",
    name: "Web Development",
    description: "Full-stack web development services.",
    providerName: "John Doe",
    providerRating: 4.8,
    providerClients: 12,
    image: "https://via.placeholder.com/300x200.png?text=Web+Development",
  },
  {
    id: "2",
    name: "Graphic Design",
    description: "Creative graphic design services.",
    providerName: "Jane Smith",
    providerRating: 4.5,
    providerClients: 20,
    image: "https://via.placeholder.com/300x200.png?text=Graphic+Design",
  },
];

const ServiceList: React.FC = () => {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
      {dummyServices.map((service) => (
        <ServiceCard key={service.id} service={service} />
      ))}
    </div>
  );
};

export default ServiceList;
