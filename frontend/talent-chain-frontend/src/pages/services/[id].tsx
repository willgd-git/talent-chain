// src/pages/service/[id].tsx
import { useRouter } from "next/router";

const ServiceDetail: React.FC = () => {
  const router = useRouter();
  const { id } = router.query;

  return (
    <div className="container mx-auto mt-8">
      <h1 className="text-3xl font-bold">Service Details - {id}</h1>
      <p>Details for service with ID {id} will be displayed here.</p>
    </div>
  );
};

export default ServiceDetail;
