// src/components/ServiceCard.tsx
import { IService } from "../types/index";
import Link from "next/link";

interface Props {
  service: IService;
}

const ServiceCard: React.FC<Props> = ({ service }) => {
  return (
    <div className="border rounded-lg shadow-lg p-4">
      <img src={service.image} alt={service.name} className="w-full h-40 object-cover rounded-md" />
      <h3 className="text-lg font-bold mt-4">{service.name}</h3>
      <p className="text-sm text-gray-600">{service.description}</p>
      <p className="text-sm mt-2">
        <strong>Provider:</strong> {service.providerName}
      </p>
      <p className="text-sm">
        <strong>Rating:</strong> {service.providerRating} ⭐️ ({service.providerClients} clients)
      </p>
      <Link href={`/service/${service.id}`} passHref>
        <button className="bg-blue-500 text-white py-2 px-4 rounded mt-4">View Details</button>
      </Link>
    </div>
  );
};

export default ServiceCard;
