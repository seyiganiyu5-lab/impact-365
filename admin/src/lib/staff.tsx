"use client";

import { createContext, useContext } from "react";

export type StaffRole = "member" | "leader" | "pastor" | "admin";

export type StaffProfile = {
  id: string;
  full_name: string | null;
  role: StaffRole;
};

export const StaffContext = createContext<StaffProfile | null>(null);

/** The signed-in leader / pastor / admin (only used inside the admin layout). */
export function useStaff() {
  return useContext(StaffContext)!;
}
