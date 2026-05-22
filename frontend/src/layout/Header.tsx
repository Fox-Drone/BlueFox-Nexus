export default function Header() {
  return (
    <div className="h-12 flex items-center px-4 border-b border-gray-800 bg-gray-900">
      <input
        className="bg-gray-800 text-white px-3 py-1 rounded w-80"
        placeholder="Search events..."
      />
    </div>
  );
}