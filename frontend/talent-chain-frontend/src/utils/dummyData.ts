// src/utils/dummyData.ts
export interface Service {
    id: number;
    image: string;
    name: string;
    description: string;
    providerName: string;
    averageRating: number;
    totalClients: number;
  }
  
  export const services: Service[] = [
    {
      id: 1,
      image: "https://via.placeholder.com/300x200.png?text=Service+1",
      name: "Web Development",
      description: "Professional web development services using modern technologies.",
      providerName: "Alice Johnson",
      averageRating: 4.5,
      totalClients: 120,
    },
    {
      id: 2,
      image: "https://via.placeholder.com/300x200.png?text=Service+2",
      name: "Graphic Design",
      description: "Creative graphic design solutions for your business needs.",
      providerName: "Bob Smith",
      averageRating: 4.8,
      totalClients: 95,
    },
    {
      id: 3,
      image: "https://via.placeholder.com/300x200.png?text=Service+3",
      name: "Digital Marketing",
      description: "Comprehensive digital marketing strategies to grow your brand.",
      providerName: "Carol Williams",
      averageRating: 4.6,
      totalClients: 110,
    },
    // Add more services as needed
  ];
  